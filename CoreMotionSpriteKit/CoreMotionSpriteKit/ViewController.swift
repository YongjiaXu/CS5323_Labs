//
//  ViewController.swift
//  CoreMotionSpriteKit
//
//  Created by John Zhang on 10/11/21.
//

import UIKit
import CoreMotion

class ViewController: UIViewController,UITextFieldDelegate,GameViewControllerDelegate{
    

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var yesterdayStepLabel: UILabel!
    @IBOutlet weak var updatingLabel: UILabel!
    @IBOutlet weak var goalField: UITextField!
    @IBOutlet weak var userFeedBack: UILabel!
    @IBOutlet weak var leftStepLabel: UILabel!
    
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    
    
    var soFarSteps:Int = 0
    var goalSteps:Int = 1000{
        didSet{
            
            userFeedBack.text = "\(goalSteps)"
            }
        }
    
    
    var updatingSteps:Int = 0
    var GameResult = 0
    var testSteps:Int = 100
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadGoal()
        
        startActivityMonitoring()
        startPedometerMonitoring()
        
        goalField.delegate = self
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let num = Int(textField.text!){
            self.goalSteps = num
            UserDefaults.standard.set(self.goalSteps, forKey: "GoalStep")

        }else{
            userFeedBack.text = "Pleas enter numbers only"
        }
        
        if Int(self.goalSteps - self.soFarSteps) > 0{
            DispatchQueue.main.async {
                self.leftStepLabel.text = "\(self.goalSteps - self.soFarSteps)"
            }
        }else{
            DispatchQueue.main.async {
                self.leftStepLabel.text = "Goal achieved!"
            }
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func setGoal(_ sender: Any) {
        
    }
    
    
    func loadGoal(){
        if UserDefaults.standard.object(forKey: "GoalStep") == nil {
            UserDefaults.standard.set(self.goalSteps, forKey: "GoalStep")
        }
        self.goalSteps = UserDefaults.standard.object(forKey: "GoalStep") as! Int
        
        
        
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
                        self.updatingLabel.text = "\(self.soFarSteps)"
                    }
                        
                        if Int(self.goalSteps - self.soFarSteps) > 0{
                            DispatchQueue.main.async {
                                self.leftStepLabel.text = "\(self.goalSteps - self.soFarSteps)"
                            }
                        }else{
                            DispatchQueue.main.async {
                                self.leftStepLabel.text = "Goal achieved!"
                            }
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
                                    
                                    if Int(self.goalSteps - self.updatingSteps) > 0{
                                        DispatchQueue.main.async {
                                            self.leftStepLabel.text = "\(self.goalSteps - self.updatingSteps)"
                                        }
                                    }else{
                                        DispatchQueue.main.async {
                                            self.leftStepLabel.text = "Goal achieved!"
                                        }
                                    }
                                    
                                }
                            }
                
            }
        }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? GameViewController{
            vc.delegate = self
        }
           
    }
    
    
    

    func CatchResult(controller:GameViewController, data:Int){
        GameResult = data                    // Got the game result
        print("I got ", GameResult)  // 0 means has not play the game
                                    // 1 means has played but failed
                                    // 2 means has played and won
    }
    
    
    
    
}

