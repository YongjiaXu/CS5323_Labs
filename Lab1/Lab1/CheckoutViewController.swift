//
//  CheckoutViewController.swift
//  Lab1
//
//  Created by xuan zhai on 9/9/21.
//

import UIKit

class CheckoutViewController: UIViewController {

    var Result:Array<Array<String>> = []
    var finalTime:Int = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var total = "Item   Spicy   Amount\n"
        for dish in Result{
            for item in dish{
                total = total + item + ",   "
            }
            total = total + "\n"
            
        }
        
        self.resultTable.text = total
        self.switchOutlet.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        let timelabel = "The time you spent on ordering food is " + finalTime.description  + "sec.\nYou must be a food lover!"
        self.LabelOutlet.text = timelabel
        // Do any additional setup after loading the view.
    }
    

    @IBOutlet weak var resultTable: UILabel!
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBOutlet weak var switchOutlet: UISwitch!
    
    
    @IBOutlet weak var LabelOutlet: UILabel!
    
    
    
    
    @IBAction func GoHome(_ sender: UIButton) {
        self.Result = []
        self.navigationController?.popToRootViewController(animated: true)
    }
}
