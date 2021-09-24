//
//  MBViewController.swift
//  AudioLabSwift
//
//  Created by xuan zhai on 9/24/21.
//  Copyright © 2021 Eric Larson. All rights reserved.
//

import UIKit

class MBViewController: UIViewController {

    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var gesteringtext: UILabel!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        slider.minimumValue = 15000         // Min inaudible tone for slider is 15k
        slider.maximumValue = 20000         // Max inaudible tone for slider is 20k
        // Do any additional setup after loading the view.
    }

}
