//
//  ModuleViewController.swift
//  Pulser
//
//  Created by Tom Gardiner on 09/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit

class ModuleViewController: UITableViewController {
	
	@IBOutlet weak var navItem: UINavigationItem!
	
	weak var delegate: ApplicationTableViewController!
	
	var app_slug: String = ""
	var modules: [Module] = []
	var modules_previous: [Module] = []
	let module_sections = [ "High Priority", "Medium Priority", "Low Priority" ]
	var modules_sorted: [[Module]] = Array(repeating: Array<Module>(), count: 3)
	
	func reloadTable() {
		// Sort the modules by timestamp, so the most recent always appears at the top
		modules.sort(by: { $0.timestamp > $1.timestamp })
		
		for (_, element) in modules.enumerated() {
			var index = 2
			switch element.urgency {
			case "low":
				index = 2; break
			case "med":
				index = 1; break
			case "high":
				index = 0; break
			default:
				index = 2; break
			}
			modules_sorted[index].append(element)
		}
		
		// Once the data has been retrieved
		// Asychronously update/reload the table view to reflect the changes
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}
	
	func refreshUpdates(_ sender: UIRefreshControl) {
		modules.removeAll()
		modules_sorted.removeAll()
		modules_sorted = Array(repeating: Array<Module>(), count: 3)
		
		Network.requestJSON("/api/applications/" + app_slug, method: Network.Method.GET, body: nil) { (res, err) in
			if (err == nil && res != nil) {
				let data = res?["data"] as! [String:Any]
				let updates = data["updates"] as! [[String:Any]]
				
				self.modules = Network.parseUpdates(updates)
				
				self.delegate.getUpdates(self.app_slug, updates: self.modules)
				
				sender.endRefreshing()
				self.reloadTable()
			}
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()

		reloadTable()
		
		self.refreshControl?.addTarget(self, action: #selector(ModuleViewController.refreshUpdates(_:)), for: UIControlEvents.valueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return modules_sorted.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modules_sorted[section].count
    }
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if (self.modules_sorted[section].count > 0) {
			return self.module_sections[section]
		} else { return nil }
		
	}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ModuleTableCell", for: indexPath) as! ModuleTableCell

		let module = modules_sorted[indexPath.section][indexPath.row]

		cell.lblUpdateText.text = module.text
		cell.imgState.image = module.image
		cell.prgValue.progress = module.value / 100

        return cell as UITableViewCell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
	
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

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
