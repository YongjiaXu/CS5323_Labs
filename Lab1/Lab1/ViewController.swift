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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.imageTapped(gesture:)))
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true
        
        
    }

    @objc func imageTapped(gesture: UIGestureRecognizer) {
            if (gesture.view as? UIImageView) != nil {
                print("Image Tapped")
                guard let vc = storyboard?.instantiateViewController(identifier: "image_vc") as? ImageViewController else {
                    return
                }
                vc.displayFoodName = displayFoodName
                present(vc, animated: true)
                // referenced: https://www.youtube.com/watch?v=AiKBxiHdFYo&ab_channel=CodeWithChris
                // https://stackoverflow.com/questions/29202882/how-do-you-make-an-uiimageview-on-the-storyboard-clickable-swift
            }
        }
    
    
    @IBAction func Goback(_ sender: Any) {
        if((delegate) != nil){
            delegate?.CatchResult(controller: self, data: displayFoodName)
            self.navigationController?.popViewController(animated: true)
        }
    }
}

