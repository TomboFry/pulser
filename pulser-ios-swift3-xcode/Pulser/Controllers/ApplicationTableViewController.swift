//
//  ApplicationTableViewController.swift
//  Pulser
//
//  Created by Tom Gardiner on 13/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit
import CoreData

class ApplicationTableViewController: UITableViewController {
	
	var applications = [Application]();
	
	func getApplications(_ sender: UIRefreshControl) {
		
		// If we're in online mode (ie. we have a connection to the pulser server)
		if Network.IsOnline {
			
			// Make a request to the applications route to get all applications and their updates
			Network.requestJSON("/api/applications", method: Network.Method.GET, body: nil) { (res, err) in
				
				// If the data we got was valid and didn't return an error
				if (err == nil && res != nil) {
					
					// First, remove all the applications in the array.
					self.applications.removeAll()
					
					let data = res?["data"] as! [[String:Any]]
					
					// Firstly delete all the applications and updates from the Core Data
					CDApplication.deleteAll(CDApplication.self)
					CDUpdate.deleteAll(CDApplication.self)
					
					// Loop through all the applications returned in the JSON
					for (_, element) in data.enumerated() {
						
						// Get the application's properties
						let app_slug = element["slug"] as! String
						let app_name = element["name"] as! String
						let app_image = element["image"] as! String
						let updates = element["updates"] as! [[String:Any]]
						let updates_array: [Module] = Module.parseUpdates(updates)
						
						// Create an application
						let app = Application(slug: app_slug, name: app_name, image: nil, updates: updates_array)
						
						// Also add it to Core Data
						let cd_app: CDApplication = CDApplication.insert()
						cd_app.slug = app_slug
						cd_app.name = app_name
						
						// Check to see if an image already exists for this application
						
						// First, get all the images currently in Core Data
						let cd_image_list: [CDImage] = CDImage.fetchAll()
						var has_cd_image: CDImage? = nil
						
						// Loop through all the images in Core Data
						for image in cd_image_list {
							
							// If we have a match, set the temporary image and break out of the loop
							if image.app_slug == app_slug {
								has_cd_image = image
								break
							}
						}
						
						// If we didn't manage to find a matching image
						// Or the matching image is empty
						if has_cd_image == nil || (has_cd_image != nil && has_cd_image?.data?.count == nil) {
							
							var cd_image: CDImage;
							
							if (has_cd_image == nil) {
								print("There was not an image for \(app.slug))")
								// Create an image with its properties
								cd_image = CDImage.insert()
							} else {
								print("There was an image but it was empty... (for application: \(has_cd_image?.app_slug))")
								cd_image = has_cd_image!
							}
							
							cd_image.app_slug = app_slug
							cd_image.application = cd_app
							
							// Download the image data from the server
							Network.request(app_image, method: Network.Method.GET, body: nil) { (img_data, img_err) in
								if img_data != nil {
									
									// Set the image's data to what was downloaded
									cd_image.data = img_data
									print("Downloaded Image (\(cd_image.data?.count))")
									cd_app.image = cd_image
									app.cd_image = cd_image
									
									// Asynchronously update the UIImage in the application
									app.updateImage()
									
									// It's slow but the only way I know it's guaranteed to actually save the image data?
									CoreDataManager.saveContext()
								}
							}
						} else {
							// However, if there was an image, we'll set it and update the UIImage
							print ("There was an image! (for application: \(cd_app.slug), size: \(has_cd_image?.data?.count))")
							has_cd_image?.application = cd_app
							cd_app.image = has_cd_image
							app.cd_image = has_cd_image
							app.updateImage()
						}
						
						// Finally, create all the Core Data updates
						for update in updates_array {
							
							// Insert it into Core Data and set its properties
							let cd_update: CDUpdate = CDUpdate.insert()
							cd_update.text = update.text
							cd_update.state = update.state
							cd_update.value = update.value
							cd_update.urgency = update.urgency
							cd_update.objectid = update.objectid
							cd_update.timestamp = Int32(update.timestamp)
							cd_update.application = cd_app
							
							// Ensure that the relationship is set up properly too
							cd_app.addToUpdates(cd_update)
						}
						
						// Finally, add the application to the array of applications for the tableview
						self.applications.append(app)
					}
					
					CDImage.emptyUnused(self.applications)
					CoreDataManager.saveContext()
				} else {
					sender.endRefreshing()
					Network.alert("Server Error", message: "Couldn't get a list of applications from the server", viewController: self)
					Network.IsOnline = false
				}
				
				// After everything is finished, reload the table
				sender.endRefreshing()
				self.reloadTable()
			}
		} else {
			applications.removeAll()
			
			applications = Application.fromCoreData()
			
			sender.endRefreshing()
			self.reloadTable()
		}
	}
	
	func reloadTable() {
		applications = Application.sort(applications)
		
		DispatchQueue.main.async(execute: {
			self.tableView.reloadData()
		})
	}
	
	func getUpdates(_ app_slug: String, updates: [Module]) {
		for app in applications {
			if app.slug == app_slug {
				app.updates.removeAll()
				app.updates = updates
				break
			}
		}
		reloadTable()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.getApplications(self.refreshControl!)
		self.refreshControl?.addTarget(self, action: #selector(ApplicationTableViewController.getApplications(_:)), for: UIControlEvents.valueChanged)

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
			let upd = app.updates[0]
			
			let updTextString = upd.text + " (" + Date(timeIntervalSince1970: TimeInterval(upd.timestamp)).timeAgoSinceNow() + " ago" + (upd.urgency == "high" ? ", high priority" : "") + ")"
			let updTextLength = updTextString.characters.count
			let updTextLocation = upd.text.characters.count
			
			let updateText = NSMutableAttributedString(string: updTextString)
			
			updateText.addAttribute(NSForegroundColorAttributeName, value: UIColor.darkText, range: NSRange(location: 0, length: updTextLocation))
			
			updateText.addAttribute(NSForegroundColorAttributeName, value: UIColor.gray, range: NSRange(location: updTextLocation, length: updTextLength - updTextLocation))
			
			cell.lblLatestUpdate.attributedText = updateText
			cell.accessoryType = .disclosureIndicator
		} else {
			cell.lblLatestUpdate.text = "No updates yet"
			cell.lblLatestUpdate.textColor = UIColor.gray
			cell.accessoryType = .none
		}
		
		cell.lblAppName.text = app.name
		cell.imgAppImage.image = app.image

        return cell as UITableViewCell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let app = applications[indexPath.row]
		
		// Only let the user view an application's updates if there are actually any.
		if app.updates.count > 0 {
			let moduleVC = storyboard?.instantiateViewController(withIdentifier: "ModuleViewController") as! ModuleViewController
			moduleVC.navItem.title = app.name
			moduleVC.modules = app.updates
			moduleVC.app_slug = app.slug
			moduleVC.delegate = self
			navigationController?.pushViewController(moduleVC, animated: true)
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
