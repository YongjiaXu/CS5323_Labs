//
//  ModuleBViewController.swift
//  ImageLab
//
//  Created by Yongjia Xu on 10/28/21.
//  Copyright © 2021 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation

class ModuleBViewController: UIViewController {

    var videoManager:VideoAnalgesic! = nil
    @IBOutlet weak var heartBeat: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        heartBeat.text = "Heart rate = calculating..."
        // Do any additional setup after loading the view.
        
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
