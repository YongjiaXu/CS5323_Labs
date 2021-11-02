//
//  ModuleBViewController.swift
//  ImageLab
//
//  Created by Yongjia Xu on 10/28/21.
//  Copyright © 2021 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate
import Metal

class ModuleBViewController: UIViewController {

    var videoManager: VideoAnalgesic! = nil
    let bridge = OpenCVBridge()
    
    var redBuffer:[Float] = []
    let needRedBufferSize = 300
    
    var heartRateArr:[Float] = []
    
    let frameRate:Double = 32.0
    
    var torchOn = false
    
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    
    @IBOutlet weak var toggleTorch: UIButton!
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var fingerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        heartRateLabel.text = "Heart rate = calculating..."
        heartRateLabel.layer.masksToBounds = true
        heartRateLabel.layer.cornerRadius = 7
        
        fingerLabel.text = "Finger Removed"
        fingerLabel.layer.masksToBounds = true
        fingerLabel.layer.cornerRadius = 7
        
        toggleTorch.layer.masksToBounds = true
        toggleTorch.layer.cornerRadius = 7
        // Do any additional setup after loading the view.
        self.videoManager = VideoAnalgesic(mainView: self.view)
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        self.videoManager.setFPS(desiredFrameRate: self.frameRate) // set the frame rate so that we can calculate heart rate easier
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImageSwift)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
        graph?.addGraph(withName: "heartRate",
                        shouldNormalize: true,
                        numPointsInGraph: self.needRedBufferSize)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        self.videoManager = nil
    }
    
    func processImageSwift(inputImage:CIImage) -> CIImage {
        
        var retImage = inputImage
        self.bridge.setTransforms(self.videoManager.transform)
        self.bridge.setImage(retImage,
                             withBounds: retImage.extent,
                             andContext: self.videoManager.getCIContext())
        let gotfinger = self.bridge.processFinger()
        retImage = self.bridge.getImageComposite()
//        if gotfinger {
//            DispatchQueue.main.async{
//                self.heartRateLabel.text = "finger detected"
//            }
//        }
//        else {
//            DispatchQueue.main.async{
//                self.heartRateLabel.text = "finger removed"
//            }
//        }
        if gotfinger {
            DispatchQueue.main.async {
                self.fingerLabel.text = ("Finger Detected")
            }
            let colorChannels = self.bridge.getColorChannels()
            self.redBuffer.append(Float(colorChannels![2]))
            
            // need to wait until buffer is full to gather enough data points
            if self.redBuffer.count == self.needRedBufferSize {
                // find peaks using sliding windows
                let windowSize = 15 // odd number of window size to ensure peak is in the middle
                // add padding to cover if peak happens on edges
                let paddingSize = windowSize/2
                let paddingArr: [Float] = [Float](repeating: 0.0, count: paddingSize)
                let fullData: [Float] = paddingArr + self.redBuffer + paddingArr
                
                // find local maxima
                var peaks = 0 // count how many peaks we found
                for i in 0...fullData.count - windowSize {
                    let window = fullData[i...i+windowSize-1]
                    var max:Float = 0.0
                    var index:UInt = 0
                    // this helps improve the performance
                    vDSP_maxvi(Array(window), vDSP_Stride(1), &max, &index, vDSP_Length(windowSize))
                    if (index == 7) { // since window size is fixed, the middle one is 7
                        peaks += 1
                    }
                }
                
                let time = Float(self.needRedBufferSize)/Float(self.frameRate)
                let heartRate = (Float(peaks)/time)*60
                
                // filter unreasonable heartRate
                if (heartRate > 40 && heartRate < 200) {
                    heartRateArr.append(heartRate)
                    if (heartRateArr.count > 10) {
                        heartRateArr.removeFirst(1)
                    }
                }
                
                var finalHeartRate = (heartRateArr.reduce(0,+))/Float(10)
                if !finalHeartRate.isNaN && !finalHeartRate.isInfinite {
                    DispatchQueue.main.async {
                        self.heartRateLabel.text = ("Heart rate = \(Int(finalHeartRate)) BPM")
                    }
                }
                else {
                    finalHeartRate = 0
                }
                
                self.redBuffer = Array(self.redBuffer[1...])
                self.updateGraph()
            }
            
        }
        else {
            DispatchQueue.main.async {
                self.heartRateLabel.text = ("Heart rate = calculating...")
                self.fingerLabel.text = ("Finger Removed")
            }
        }
        
        
//        self.bridge.setTransforms(self.videoManager.transform)

//        self.bridge.processImage()
//        retImage = self.bridge.getImageComposite()
        
        
        
        return retImage
    }
    
    @objc
    func updateGraph(){
        
        self.graph?.updateGraph(
            data: self.redBuffer,
            forKey: "heartRate"
        )
    }
    @IBAction func toggleTorchOnOff(_ sender: Any) {
        if !torchOn {
            let _ = self.videoManager.turnOnFlashwithLevel(1.0)
        }
        else {
            let _ = self.videoManager.turnOffFlash()
        }
        self.torchOn = !self.torchOn
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
