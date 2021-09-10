//
//  MapViewController.swift
//  Lab1
//
//  Created by xuan zhai on 9/9/21.
//

import UIKit

class MapViewController: UIViewController {

    var names = NSArray()
    var calories = NSArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var printout = "Food    Calories\n"
        if(names[names.count-1] as! String == ""){
            for i in 0...(names.count-1){
                let newname = names[i] as! String
                let newcal = calories[i] as! String
                printout = printout + newname + "  " + newcal + "\n"
            }
        }
        else{
            for i in 0...(names.count){
                let newname = names[i] as! String
                let newcal = calories[i] as! String
                printout = printout + newname + "  " + newcal + "\n"
            }
        }
        OutputLabel.text = printout
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var OutputLabel: UILabel!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
