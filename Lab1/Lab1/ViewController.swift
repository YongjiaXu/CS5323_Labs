//
//  ViewController.swift
//  Lab1
//
//  Created by Yongjia Xu on 9/6/21.
//

import UIKit

protocol ViewControllerDelegate : NSObjectProtocol {
    func CatchResult(controller:ViewController, data:Array<String>)
}


extension UIImage{
    //"https://blog.csdn.net/mo_xiao_mo/article/details/52612549"
    func reSizeImage(reSize: CGSize)-> UIImage {
        UIGraphicsBeginImageContextWithOptions(reSize, false, UIScreen.main.scale);
        self .draw( in: CGRect (x:0, y:0, width: reSize.width, height: reSize.height));
        let reSizeImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndPDFContext();
        return reSizeImage;
    }
    
    func scaleImage(scaleSize: CGFloat)-> UIImage {
        let reSize = CGSize(width: self.size.width*scaleSize, height: self.size.height*scaleSize)
        return reSizeImage(reSize: reSize)
    }
}


class ViewController: UIViewController  {

    
    var delegate: ViewControllerDelegate?
    
    
    var timer = Timer()
    var timeinsec = 0;
    
    
    lazy var foodModel:FoodModel = {
        return FoodModel.sharedInstance()
    }()
    

    
    var displayFoodName = "Spicy-Fish"
    
    
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        valueLabel.text = "Amount: " + Int(sender.value).description
    }
    
    
    @objc func updateTimer() {
        timeinsec = timeinsec + 1
        timerLabel.text = "You're wasting " + timeinsec.description + "sec on ordering food!"
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView?.image = self.foodModel.getImageWithName(displayFoodName)
        self.label.text = displayFoodName
        
        self.slider.minimumValueImage = UIImage.init(named: "mild")?.scaleImage(scaleSize: 0.75)
        self.slider.maximumValueImage = UIImage.init(named: "hot")?.scaleImage(scaleSize: 0.75)
        self.slider.maximumValue = 3
        self.slider.minimumValue = 0
        
        self.stepper.wraps = true;
        self.stepper.autorepeat = true;
        self.stepper.maximumValue = 100;
        self.stepper.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.imageTapped(gesture:)))
        imageView.addGestureRecognizer(tapGesture)
        imageView.isUserInteractionEnabled = true
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
        
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
            var newspicy = self.slider.value
            newspicy = Float(round(10*newspicy)/10)
            timer.invalidate()

            let newarray = [displayFoodName, newspicy.description, self.stepper.value.description, self.timeinsec.description]
            delegate?.CatchResult(controller: self, data: newarray)
            self.navigationController?.popViewController(animated: true)
        
        }
    }
}

