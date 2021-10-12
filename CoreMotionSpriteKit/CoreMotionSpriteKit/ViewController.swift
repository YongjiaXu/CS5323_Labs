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
    @IBOutlet weak var currentStepLabel: UILabel!
    @IBOutlet weak var yesterdayStepLabel: UILabel!
    
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        startActivityMonitoring()
        startPedometerMonitoring()
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
    
    func startPedometerMonitoring(){
            // check if pedometer is okay to use
            if CMPedometer.isStepCountingAvailable(){
                guard let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else{
                    return
                }
                                                      
                pedometer.queryPedometerData(from: Calendar.current.startOfDay(for: pastDate), to: pastDate)
                {(pedData:CMPedometerData?, error:Error?)->Void in
                    if let data = pedData {
                        
                        // display the output directly on the phone
                          DispatchQueue.main.async {
                            self.yesterdayStepLabel.text = "\(data.numberOfSteps.intValue)"
                        }
                    }
                }
                pedometer.queryPedometerData(from: Calendar.current.startOfDay(for: Date()), to: Date())
                {(pedData:CMPedometerData?, error:Error?)->Void in
                    if let data = pedData {
                        
                        // display the output directly on the phone
                          DispatchQueue.main.async {
                            self.currentStepLabel.text = "\(data.numberOfSteps.intValue)"
                        }
                    }
                }
                
            }
        }

    
    
}

