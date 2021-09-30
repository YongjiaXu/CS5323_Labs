//
//  MBViewController.swift
//  AudioLabSwift
//
//  Created by xuan zhai on 9/24/21.
//  Copyright © 2021 Eric Larson. All rights reserved.
//

import UIKit
import Metal

class MBViewController: UIViewController {
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var Frequencytext: UILabel!
    
    @IBOutlet weak var gesteringtext: UILabel!
    
    let audioI = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
   }()
    
    
    @IBAction func changeFrequency(_ sender: UISlider) {
        self.audioI.sineFrequency = sender.value
        Frequencytext.text = "Frequency: \(sender.value)"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AUDIO_BUFFER_SIZE/2)
        
        
        slider.minimumValue = 15000         // Min inaudible tone for slider is 15k
        slider.maximumValue = 20000         // Max inaudible tone for slider is 20k
        audioI.startMicrophoneProcessing(withFps: 60.0)
        audioI.startProcessingSinewaveForPlayback(withFreq: 15000,withFps: 60.0)
        audioI.play()
        
        // Do any additional setup after loading the view.
        
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
        
    }
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioI.pause()
        print("paused")
    }
    
    
    
    
    @objc
    func updateGraph(){
        
        //self.loudestLabel.text = "Loudest: \(self.audio.loudestTone) Hz"
        //self.secondLoudestLabel.text = "Second Loudest: \(self.audio.secondLoudestTone) Hz"
        self.gesteringtext.text = self.audioI.gesturingstatus
        self.graph?.updateGraph(
            data: self.audioI.fftData,
            forKey: "fft"
        )
    }

}
