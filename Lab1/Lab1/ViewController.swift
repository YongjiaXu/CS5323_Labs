//
//  ViewController.swift
//  Lab1
//
//  Created by Yongjia Xu on 9/6/21.
//

import UIKit

protocol ViewControllerDelegate : NSObjectProtocol {
    func CatchResult(controller:ViewController, data:String)
}



class ViewController: UIViewController  {

    
    var delegate: ViewControllerDelegate?
    
    
    
    
    
    lazy var foodModel:FoodModel = {
        return FoodModel.sharedInstance()
    }()
    

    
    var displayFoodName = "Spicy-Fish"
    
    
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        valueLabel.text = "Value: " + Int(sender.value).description
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView?.image = self.foodModel.getImageWithName(displayFoodName)
        self.label.text = displayFoodName
        
        self.slider.minimumValueImage = UIImage.init(named: "mild")
        self.slider.maximumValueImage = UIImage.init(named: "hot")
        
        self.stepper.wraps = true;
        self.stepper.autorepeat = true;
        self.stepper.maximumValue = 100;
        
        
        
        
        // Do any additional setup after loading the view.
    }

    
    
    
    
    
    @IBAction func Goback(_ sender: Any) {
        if((delegate) != nil){
            delegate?.CatchResult(controller: self, data: displayFoodName)
            self.navigationController?.popViewController(animated: true)
        }
    }
}

