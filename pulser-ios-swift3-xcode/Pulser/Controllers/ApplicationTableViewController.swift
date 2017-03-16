//
//  ApplicationTableViewController.swift
//  Pulser
//
//  Created by Tom Gardiner on 13/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit

class ApplicationTableViewController: UITableViewController {
	
	var applications = [Application]();
	
	func getApplications() {
		Network.requestJSON("/api/applications", method: Network.Method.GET, body: nil) { (result, err) in
			if (err == nil && result != nil) {
				let data = result?["data"] as! [[String:Any]]
				for (_, element) in data.enumerated() {
					let app_slug = element["slug"] as! String
					let app_name = element["name"] as! String
					let app_image = element["image"] as! String
					let updates = element["updates"] as! [[String:Any]]
					var updates_array = [Module]()
					for (_, update) in updates.enumerated() {
						let mod_text = update["text"] as! String
						let mod_value = NSString(string: update["value"] as! String).floatValue
						let mod_state = update["state"] as! String
						let mod_urgency = update["urgency"] as! String
						let mod_timestamp = update["timestamp"] as! Int
						
						let mod = Module(text: mod_text, value: mod_value, state: mod_state, urgency: mod_urgency, timestamp: mod_timestamp)
						
						updates_array.append(mod!)
					}
					
					// Sort the updates by timestamp, so the most recent always appears at the top
					updates_array.sort(by: { $0.timestamp > $1.timestamp })
					
					let app = Application(slug: app_slug, name: app_name, image_url: app_image, updates: updates_array)
					
					self.applications.append(app)
					
					DispatchQueue.main.async(execute: {
						self.tableView.reloadData()
					})
				}

			} else {
				return Network.alert("Server Error", message: "Couldn't get a list of applications from the server")
			}
		}
	}

	func reloadTable() {
		// Once the data has been retrieved
		// Asychronously update/reload the table view to reflect the changes
		
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		getApplications()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return applications.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ApplicationTableViewCell", for: indexPath) as! ApplicationTableViewCell
		
		let app = applications[indexPath.row]
		
		if app.updates.count > 0 {
			print(app.updates[0].text)
			let upd = app.updates[0]
			// TODO FIX PLS
			cell.lblLatestUpdate.text = upd.text + " (" + Date(timeIntervalSince1970: TimeInterval(upd.timestamp)).timeAgoSinceNow() + ")"
			cell.lblLatestUpdate.textColor = UIColor.darkText
		} else {
			cell.lblLatestUpdate.text = "No updates yet"
			cell.lblLatestUpdate.textColor = UIColor.gray
		}
		
		cell.lblAppName.text = app.name
		cell.imgAppImage.image = app.image

        return cell as UITableViewCell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let app = applications[indexPath.row]
		
		let moduleVC = storyboard?.instantiateViewController(withIdentifier: "ModuleViewController") as! ModuleViewController
		moduleVC.navItem.title = app.name
		moduleVC.modules = app.updates
		navigationController?.pushViewController(moduleVC, animated: true)
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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
