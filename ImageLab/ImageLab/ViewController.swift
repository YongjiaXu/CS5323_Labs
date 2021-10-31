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
    var filter : CIFilter! = nil
    var eyeFilter : CIFilter! = nil
    var mouthFilter : CIFilter! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var isovering = false
    var notoveringtimer = 0
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
    
    @IBOutlet weak var toggleflash: UIButton!
    //MARK: Outlets in view
    @IBOutlet weak var flashSlider: UISlider!
    @IBOutlet weak var stageLabel: UILabel!
    
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
//            filters = []
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
                    filter.setValue(retImage, forKey: kCIInputImageKey)
                    filter.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                    filter.setValue(f.bounds.width/2, forKey: "inputRadius")
                    // could also manipulate the radius of the filter based on face size!
                    retImage = filter.outputImage!
                
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
    
    //MARK: Setup Face Detection
    
    
    
    
    // change the type of processing done in OpenCV
    @IBAction func swipeRecognized(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .left:
            self.bridge.processType += 1
        case .right:
            self.bridge.processType -= 1
        default:
            break
            
        }
        
        stageLabel.text = "Stage: \(self.bridge.processType)"

    }
    
    //MARK: Convenience Methods for UI Flash and Camera Toggle
    @IBAction func flash(_ sender: AnyObject) {
        if(self.videoManager.toggleFlash()){
            self.flashSlider.value = 1.0
        }
        else{
            self.flashSlider.value = 0.0
        }
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        self.videoManager.toggleCameraPosition()
    }
    
    @IBAction func setFlashLevel(_ sender: UISlider) {
        if(sender.value>0.0){
            let val = self.videoManager.turnOnFlashwithLevel(sender.value)
            if val {
                print("Flash return, no errors.")
            }
        }
        else if(sender.value==0.0){
            self.videoManager.turnOffFlash()
        }
    }

   
}

