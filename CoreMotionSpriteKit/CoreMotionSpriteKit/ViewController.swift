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
    @IBOutlet weak var updatingLabel: UILabel!
    
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    
    var soFarSteps = 0
    var goalSteps = 0
    var updatingSteps = 0
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startActivityMonitoring()
        startPedometerMonitoring()
    }

    func setGoal(){
        
    }
    
    func gameOrNot(){
        
    }
    
    func loadGoal(){
        
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
                let startToday = Calendar.current.startOfDay(for: Date())
                let startYesterday = startToday.addingTimeInterval(-60*60*24)
                //var todaySteps = 0
                                                      
                pedometer.queryPedometerData(from: startYesterday, to:startToday)
                {(pedData:CMPedometerData?, error:Error?)->Void in
                    if let data = pedData {
                         //display the output directly on the phone
                          DispatchQueue.main.async {
                            self.yesterdayStepLabel.text = "\(data.numberOfSteps.intValue)"
                        }
                    }
                }
                
                
                pedometer.queryPedometerData(from: startToday, to: Date())
                {(pedData:CMPedometerData?, error:Error?)->Void in
                    if let data = pedData {
                        self.soFarSteps = data.numberOfSteps.intValue
                        
                        DispatchQueue.main.async {
                            self.currentStepLabel.text = "\(self.soFarSteps)"
                        }
                       
                    }
                }
                
                pedometer.startUpdates(from: Date())
                            {(pedData:CMPedometerData?, error:Error?)->Void in
                                if let data = pedData {
                                    self.updatingSteps = data.numberOfSteps.intValue + self.soFarSteps
                                    DispatchQueue.main.async {
                                        self.updatingLabel.text = "\(self.updatingSteps)"
                                    }
                                }
                            }
                
            }
        }

    
    
    
    
}

