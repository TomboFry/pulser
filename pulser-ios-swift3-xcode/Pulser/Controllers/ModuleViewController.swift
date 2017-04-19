//
//  ModuleViewController.swift
//  Pulser
//
//  Created by Tom Gardiner on 09/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit
import PromiseKit

class ModuleViewController: UITableViewController {
	
	@IBOutlet weak var navItem: UINavigationItem!
	
	weak var delegate: ApplicationTableViewController!
	
	var app_slug: String = ""
	var modules: [Module] = []
	var modules_previous: [Module] = []
	let module_sections = [ "High Priority", "Medium Priority", "Low Priority" ]
	var modules_sorted: [[Module]] = Array(repeating: Array<Module>(), count: 3)
	
	var update_delete_row: IndexPath? = nil
	
	func reloadTable() {
		// Sort the modules by timestamp, so the most recent always appears at the top
		modules.sort(by: { $0.timestamp > $1.timestamp })
		
		self.delegate.getUpdates(self.app_slug, updates: self.modules)
		
		// Empty the sorted array so we don't end up with duplicates on refreshing and deleting.
		modules_sorted.removeAll()
		modules_sorted = Array(repeating: Array<Module>(), count: 3)
		
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
		if Network.IsOnline {
			Network.requestJSON("/api/applications/" + self.app_slug, method: .GET, body: nil).then { result -> Promise<()> in
				let data = result["data"] as! [String:Any]
				let updates = data["updates"] as! [[String:Any]]
				
				self.modules = Module.parseUpdates(updates)
				self.reloadTable()
				sender.endRefreshing()
				return Promise(value: ())
			}.catch { _ in
				sender.endRefreshing()
				Network.IsOnline = false
			}
		} else {
			self.modules = Module.fromCoreData(with: self.app_slug)
			sender.endRefreshing()
			self.reloadTable()
		}
	}
	
	func confirmDelete() {
		let alert = UIAlertController(title: "Remove Module", message: "Are you sure you want to permanently delete this update?", preferredStyle: .actionSheet)
		
		let DeleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDelete)
		let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction) in
			self.update_delete_row = nil
		})
		
		alert.addAction(DeleteAction)
		alert.addAction(CancelAction)
		
		self.present(alert, animated: true, completion: nil)
	}
	
	func handleDelete(_ alertAction: UIAlertAction) {
		if let indexPath = update_delete_row {
			let update = modules_sorted[indexPath.section][indexPath.row]
			
			let handleTable = {
				DispatchQueue.main.async {
					// Begin removing the module from the arrays and tableview
					self.tableView.beginUpdates()
					for (idx, md) in self.modules.enumerated() {
						if md.objectid == update.objectid {
							self.modules.remove(at: idx)
							break
						}
					}
					self.modules_sorted[indexPath.section].remove(at: indexPath.row)
					self.tableView.deleteRows(at: [indexPath], with: .fade)
					self.update_delete_row = nil
					self.tableView.endUpdates()
					self.reloadTable()
				}
			}
			
			if Network.IsOnline {
				Network.requestJSON("/api/applications/\(app_slug)/updates/\(update.objectid)", method: .DELETE, body: nil).then { _ in
					// Only remove the update if it was successfully removed from the server too
					handleTable()
				}.catch { error in
					Network.alert("Error occurred", message: error.localizedDescription, viewController: self)
				}
			} else {
				// Add a "DeleteOnSync" instance if in Offline Mode
				let cd_delete: CDDeleteOnSync = CDDeleteOnSync.insert()
				cd_delete.objectid = update.objectid
				cd_delete.app_slug = app_slug
				
				CDUpdate.delete(CDUpdate.self, key: "objectid", value: update.objectid)
				
				CoreDataManager.saveContext()
				handleTable()
			}
		}
	}
	
	// MARK: - Override Default Swift Methods

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
		cell.lblTimeAgo.text = Date(timeIntervalSince1970: TimeInterval(module.timestamp)).timeAgoSinceNow()
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
			update_delete_row = indexPath
            confirmDelete()
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
