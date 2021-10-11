//
//  ViewController.swift
//  CoreMotionSpriteKit
//
//  Created by John Zhang on 10/11/21.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet weak var statusLabel: UILabel!
    
    let activityManager = CMMotionActivityManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startActivityMonitoring()
    }


    func startActivityMonitoring(){
            if CMMotionActivityManager.isActivityAvailable(){
                self.activityManager.startActivityUpdates(to: OperationQueue.main)
                {(activity:CMMotionActivity?)->Void in
                    if let unwrappedActivity = activity {
                                            
                        print(unwrappedActivity.description)
                        if(unwrappedActivity.walking){
                            self.statusLabel.text = "Walking"
                        }
                        else if(unwrappedActivity.running){
                            self.statusLabel.text = "Running"
                        }
                        else if(unwrappedActivity.cycling){
                            self.statusLabel.text = "Cycling"
                        }
                        else if(unwrappedActivity.automotive){
                            self.statusLabel.text = "Driving"
                        }
                        else if(unwrappedActivity.stationary){
                            self.statusLabel.text = "Still"
                        }
                        else{
                            self.statusLabel.text = "Unknown"
                        }
                    }
                }
            }
            
        }
    
}

