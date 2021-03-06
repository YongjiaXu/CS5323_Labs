//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import UIKit
import Metal


let AUDIO_BUFFER_SIZE = 1024*4*4


class ViewController: UIViewController {

    
    @IBOutlet weak var loudestLabel: UILabel!
    @IBOutlet weak var secondLoudestLabel: UILabel!
    let audio = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loudestLabel.layer.masksToBounds = true
        loudestLabel.layer.cornerRadius = 7
        secondLoudestLabel.layer.masksToBounds = true
        secondLoudestLabel.layer.cornerRadius = 7
        // add in graphs for display
        graph?.addGraph(withName: "space",
                        shouldNormalize: false,
                        numPointsInGraph: 1)
        
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AUDIO_BUFFER_SIZE/2)
        
        graph?.addGraph(withName: "time",
            shouldNormalize: false,
            numPointsInGraph: AUDIO_BUFFER_SIZE)

        
        audio.startMicrophoneProcessing(withFps: 60.0)
        audio.play()
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
       
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audio.pause()
        print("paused")
    }
    
    
    @objc
    func updateGraph(){
        
        self.loudestLabel.text = "  Loudest: \(self.audio.loudestTone) Hz"
        self.secondLoudestLabel.text = "  Second Loudest: \(self.audio.secondLoudestTone) Hz"
        
        self.graph?.updateGraph(
            data: self.audio.fftData,
            forKey: "fft"
        )
        
        self.graph?.updateGraph(
            data: self.audio.timeData,
            forKey: "time"
        )
        
    }
    
    

}

