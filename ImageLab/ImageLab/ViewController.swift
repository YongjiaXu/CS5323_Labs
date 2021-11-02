//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController   {

    //MARK: Class Properties
    var filter : CIFilter! = nil //filter for face and eyes
    var mouthFilter : CIFilter! = nil//filter for mouth
    var eyeFilter : CIFilter! = nil//filter for eye
    
    var faceDetection = true //face detection on as default
    var eyeMouthDetection = false //eye&mouth detection off as default
    var manyFaces = false
    var leftEyeBlink = false
    var rightEyeBlink = false
    var leftEyeClosed = false
    var rightEyeClosed = false
    
    var videoManager:VideoAnalgesic! = nil
    let bridge = OpenCVBridge()
    
    lazy var detector:CIDetector! = {
            // create dictionary for face detection
            // HINT: you need to manipulate these properties for better face detection efficiency
            let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyHigh, CIDetectorTracking:true] as [String : Any]
            
            // setup a face detector in swift
            let detector = CIDetector(ofType: CIDetectorTypeFace,
                                      context: self.videoManager.getCIContext(), // perform on the GPU is possible
                options: (optsDetector as [String : AnyObject]))
            
            return detector
        }()
    
    @IBOutlet weak var togglecamera: UIButton!
    @IBOutlet weak var smileLabel: UILabel!
    @IBOutlet weak var eyeLabel: UILabel!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        togglecamera.layer.masksToBounds = true
        togglecamera.layer.cornerRadius = 7
        self.setupFilters()

        // setup the OpenCV bridge nose detector, from file
        self.bridge.loadHaarCascade(withFilename: "nose")
        
        self.videoManager = VideoAnalgesic(mainView: self.view)    // Change the camera to back
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.videoManager = nil
    }
    
    //MARK: Setup filtering
        func setupFilters(){
            filter = CIFilter(name:"CIBumpDistortion") //set face filter to CIBumpDistortion
            eyeFilter = CIFilter(name:"CIVortexDistortion") //set eye filter to CIVortexDistortion
            mouthFilter = CIFilter(name: "CITwirlDistortion")//set mouth filter to CITwirlDistortion
        }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        // add CIDetectorEyeBlink and CIDetectorSmile
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation, CIDetectorEyeBlink: true, CIDetectorSmile: true] as [String : Any]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]
        
    }
    
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
            var retImage = inputImage
            var filterCenter = CGPoint()
            
            for f in features {
                //set where to apply filter
                filterCenter.x = f.bounds.midX
                filterCenter.y = f.bounds.midY
                
                //do for each filter (assumes all filters have property, "inputCenter")
                //if face detection is on
                if faceDetection{
                    filter.setValue(retImage, forKey: kCIInputImageKey)
                    filter.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                    filter.setValue(f.bounds.width*4/5, forKey: "inputRadius")
                    retImage = filter.outputImage!
                }
                //if eye&mouth detection is on
                if eyeMouthDetection{
                    //if facefeatures have left eye
                    if f.hasLeftEyePosition{
                        eyeFilter.setValue(retImage, forKey: kCIInputImageKey)
                        eyeFilter.setValue(CIVector(cgPoint: f.leftEyePosition), forKey: "inputCenter")//set center on left eye
                        eyeFilter.setValue(f.bounds.width/10, forKey: "inputRadius")
                        retImage = eyeFilter.outputImage!
                    }
                    
                    //if facefeatures have right eye
                    if f.hasRightEyePosition{
                        eyeFilter.setValue(retImage, forKey: kCIInputImageKey)
                        eyeFilter.setValue(CIVector(cgPoint: f.rightEyePosition), forKey: "inputCenter")//set center on right eye
                        eyeFilter.setValue(f.bounds.width/10, forKey: "inputRadius")
                        retImage = eyeFilter.outputImage!
                    }
                    
                    //if facefeatures have mouth
                    if f.hasMouthPosition{
                        mouthFilter.setValue(retImage, forKey: kCIInputImageKey)
                        mouthFilter.setValue(CIVector(cgPoint: f.mouthPosition), forKey: "inputCenter")//set center on mouth
                        mouthFilter.setValue(f.bounds.width/7, forKey: "inputRadius")
                        retImage = mouthFilter.outputImage!
                    }
                }
                // if there is only one face
                if !manyFaces {
                    // if detect smile
                    if f.hasSmile{
                        DispatchQueue.main.async{
                            self.smileLabel.text = "Smiling!"
                        }
                    }else{
                        DispatchQueue.main.async{
                            self.smileLabel.text = "Not smiling!"
                        }
                    }
                    
                    if f.leftEyeClosed{
                        leftEyeClosed = true
                    }else {
                        if leftEyeClosed == true{
                            leftEyeBlink = true
                            leftEyeClosed = false
                        }
                    }
                    
                    if f.rightEyeClosed{
                        rightEyeClosed = true
                    }else{
                        if rightEyeClosed == true{
                            rightEyeBlink = true
                            rightEyeClosed = false
                        }
                    }
                    
                }else{
                    DispatchQueue.main.async{
                        self.smileLabel.text = ""
                    }
                }
                
                if leftEyeBlink == true && rightEyeBlink == true{
                    DispatchQueue.main.async{
                        self.eyeLabel.text = "both eye blink"
                    }
                }else if leftEyeBlink == true && rightEyeBlink == false{
                    DispatchQueue.main.async{
                        self.eyeLabel.text = "left eye blink"
                    }
                }else if leftEyeBlink == false && rightEyeBlink == true{
                    DispatchQueue.main.async{
                        self.eyeLabel.text = "right eye blink"
                    }
                }
                
                leftEyeBlink = false
                rightEyeBlink = false
                
                
            }
            return retImage
        }
    
    //MARK: Process image output
    func processImageSwift(inputImage:CIImage) -> CIImage{
        
        // detect faces
                let faces = getFaces(img: inputImage)
                
                // if no faces, just return original image
                if faces.count == 0 {
                    return inputImage
                }else if faces.count == 1{
                    manyFaces = false
                }else{
                    manyFaces = true
                }
        
                //otherwise apply the filters to the faces
                return applyFiltersToFaces(inputImage: inputImage, features: faces)
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }
    // turn on/off face detection and set faceDetection to true/false
    @IBAction func FaceDetectionSwitch(_ sender: UISwitch) {
        if faceDetection == true{
            faceDetection = false
        }else if faceDetection == false{
            faceDetection = true
        }
    }
    //turn on/off eye&mouth detection and set eyeMouthDetection to true/false
    @IBAction func EyeMouthDetectionSwitch(_ sender: UISwitch) {
        if eyeMouthDetection == true{
            eyeMouthDetection = false
        }else if eyeMouthDetection == false{
            eyeMouthDetection = true
        }
    }
    
}

