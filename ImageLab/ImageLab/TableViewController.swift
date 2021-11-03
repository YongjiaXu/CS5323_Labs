//
//  TableViewController.swift
//  ImageLab
//
//  Created by xuan zhai on 11/2/21.
//  Copyright © 2021 Eric Larson. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleA", for: indexPath)

        // Configure the cell...
            cell.textLabel?.text = "Module A"
        return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleB", for: indexPath)

            // Configure the cell...
            cell.textLabel?.text = "Module B"
            return cell
        }
    }

}
