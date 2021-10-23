//
//  ViewController.swift
//  CoreMotionSpriteKit
//
//  Created by John Zhang on 10/11/21.
//

import UIKit
import CoreMotion

class ViewController: UIViewController,UITextFieldDelegate,GameViewControllerDelegate{
    
    @IBOutlet weak var gameLabel: UILabel!
    @IBOutlet weak var gamebutton: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var yesterdayStepLabel: UILabel!
    @IBOutlet weak var updatingLabel: UILabel!
    @IBOutlet weak var goalField: UITextField! //the only text field in the app
    @IBOutlet weak var userFeedBack: UILabel!
    @IBOutlet weak var gifView: UIImageView!
    @IBOutlet weak var leftStepLabel: UILabel!
    
    let activityManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    
    
    var soFarSteps:Int = 0
    var goalSteps:Int = 8000{
        didSet{
            userFeedBack.text = "\(goalSteps)"
            }
        }
    
    
    var updatingSteps:Int = 0
    var GameResult = 0
    var testSteps:Int = 100
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        gamebutton.layer.masksToBounds = true
        gamebutton.layer.cornerRadius = 7
        gifView.loadGif(name: "walking")
        loadGoal()
        
        startActivityMonitoring()
        startPedometerMonitoring()
        
        goalField.delegate = self
        gamebutton.isHidden = true
    }

    //receive the number only data in the textfield and set goal to that number. If you have alredy walked
    //1000 today and you set a goal of 500, this function will set leftStepLabel.text to "Goal achieved"
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let num = Int(textField.text!){
            self.goalSteps = num
            UserDefaults.standard.set(self.goalSteps, forKey: "GoalStep")

        }else{
            userFeedBack.text = "Number Only!!"
        }
        
        if Int(self.goalSteps - self.soFarSteps) > 0{
            DispatchQueue.main.async {
                self.leftStepLabel.text = "\(self.goalSteps - self.soFarSteps)"
                self.gamebutton.isHidden = true
                self.gameLabel.text = "Keep it up! The game is still locked."
            }
        }else{
            DispatchQueue.main.async {
                self.leftStepLabel.text = "Goal achieved!"
                self.gamebutton.isHidden = false
                self.gameLabel.text = "Congratulation! Play the game!"
            }
        }
        print(self.goalSteps)
        print(self.soFarSteps)
        textField.resignFirstResponder()
        return true
    }
    
    // load goal from GoalStep which is a key in Info.plist and set goalSteps with that number
    func loadGoal(){
        if UserDefaults.standard.object(forKey: "GoalStep") == nil {
            UserDefaults.standard.set(self.goalSteps, forKey: "GoalStep")
        }
        self.goalSteps = UserDefaults.standard.object(forKey: "GoalStep") as! Int
    }
    
    
    // monitor user's activity(Walking, Running, Cycling, Driving, Still, and Unknown)
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
    
    // three steps in this function
    func startPedometerMonitoring(){
            // check if pedometer is okay to use
            if CMPedometer.isStepCountingAvailable(){
                let startToday = Calendar.current.startOfDay(for: Date())
                let startYesterday = startToday.addingTimeInterval(-60*60*24)
                //var todaySteps = 0
                                                      
                // The first step is loading the step from the start of yesterday to the end of yesterday
                pedometer.queryPedometerData(from: startYesterday, to:startToday)
                {(pedData:CMPedometerData?, error:Error?)->Void in
                    if let data = pedData {
                         //display the output directly on the phone
                          DispatchQueue.main.async {
                            self.yesterdayStepLabel.text = "\(data.numberOfSteps.intValue)"
                        }
                    }
                }
                
                //The second step is loading steps from the start of today to now as soFarSteps
                //If soFarSteps >= goalSteps, show "Goal achieved"
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
                                self.gamebutton.isHidden = true
                                self.gameLabel.text = "Keep it up! The game is still locked."
                            }
                        }else{
                            DispatchQueue.main.async {
                                self.leftStepLabel.text = "Goal achieved!"
                                self.gamebutton.isHidden = false
                                self.gameLabel.text = "Congratulation! Play the game!"
                            }
                        }
                       
                    
                }
                }
                
                //The third step is keeping unpdating the current steps and check if the steps achieve the goal or not
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
                                            self.gamebutton.isHidden = true
                                            self.gameLabel.text = "Keep it up! The game is still locked."
                                        }
                                    }else{
                                        DispatchQueue.main.async {
                                            self.leftStepLabel.text = "Goal achieved!"
                                            self.gamebutton.isHidden = false
                                            self.gameLabel.text = "Congratulation! Play the game!"
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
        if (GameResult == 1){
            self.gameLabel.text = "You lost the game, please try it tomorrow"
        }
        else{
            self.gameLabel.text = "You won the game, you goal step now -5! "
            self.goalSteps = self.goalSteps - 5    // as a bonus, your goal step will -5.
        }                           // 0 means has not play the game
                                    // 1 means has played but failed
                                    // 2 means has played and won
        self.gamebutton.isHidden = true
    }
    
    
    @IBAction func setGoal(_ sender: Any) {
        
    }
    @IBAction func didCancelKeyboard(_ sender: Any) {
        self.goalField.resignFirstResponder()
        
    }
    
}

