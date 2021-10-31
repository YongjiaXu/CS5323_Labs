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
    var faceDetection = true
    var eyeMouthDetection = false
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
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    //MARK: Setup filtering
        func setupFilters(){
            filter = CIFilter(name:"CITwirlDistortion")
//            let filterPinch = CIFilter(name:"CIBumpDistortion")!
//            filterPinch.setValue(-0.5, forKey: "inputScale")
//            filterPinch.setValue(75, forKey: "inputRadius")
//            filters.append(filterPinch)
            
        }
    
    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation]
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
                if faceDetection{
                    filter.setValue(retImage, forKey: kCIInputImageKey)
                    filter.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                    filter.setValue(f.bounds.width*2/3, forKey: "inputRadius")
                    retImage = filter.outputImage!
                }
                
            }
            return retImage
        }
    
    //MARK: Process image output
    func processImageSwift(inputImage:CIImage) -> CIImage{
        
        // detect faces
                let faces = getFaces(img: inputImage)
                
                // if no faces, just return original image
                if faces.count == 0 { return inputImage }
                
                //otherwise apply the filters to the faces
                return applyFiltersToFaces(inputImage: inputImage, features: faces)
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }
    
    @IBAction func FaceDetectionSwitch(_ sender: UISwitch) {
        if faceDetection == true{
            faceDetection = false
        }else if faceDetection == false{
            faceDetection = true
        }
    }
    
   
}

