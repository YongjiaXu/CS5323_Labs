//
//  TableViewController.swift
//  Lab1
//
//  Created by xuan zhai on 9/7/21.
//

import UIKit



class TableViewController: UITableViewController, ViewControllerDelegate {
    
    var testnum = "default"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    var cart:Array<Array<String>> = []
    var totaltime:Int = 0
    
    
    lazy var foodModel:FoodModel = {
        return FoodModel.sharedInstance()
    }()
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0{
        return self.foodModel.foodNames.count - 1
        }
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodNameCell", for: indexPath)

        // Configure the cell...
        if let name = self.foodModel.foodNames[indexPath.row] as? String{
            cell.textLabel!.text = name
        }
        return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "CollectiveCell", for: indexPath)

            // Configure the cell...
            cell.textLabel?.text = "All Food Images"
            cell.detailTextLabel?.text = "summary"
            
            return cell
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
            if let vc = segue.destination as? ViewController,
               let cell = sender as? UITableViewCell,
               let name = cell.textLabel?.text {
                    vc.displayFoodName = name
                    vc.delegate = self
            }
        
            else if let vc = segue.destination as? CheckoutViewController {
                vc.Result = cart
                vc.finalTime = totaltime
                cart = []
            }
        }
    
    
    
    func CatchResult(controller: ViewController,  data: Array<String>){
        let newdish: Array<String> = [data[0], data[1], data[2]]
        let temptime: Int = Int(data[3]) ?? 0
        totaltime = totaltime + temptime
        cart.append(newdish)
    }
    

}
