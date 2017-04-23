//
//  ApplicationTableViewController.swift
//  Pulser
//
//  Created by Tom Gardiner on 13/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit

class ApplicationTableViewController: UITableViewController {
	
	// The main place our applications and updates will be stored
	var applications: [Application] = []
	// This is used to test whether new updates were made to the server
	// so we know what to put in the notifications (if any)
	var applications_previous: [Application] = []
	// This timer re-downloads all applications periodically in order
	// to send out notifications
	var timer: Timer?
	
	var exitToLogin: Bool = false
	
	// Use this to change whether the text displays "Login" or "Logout"
	@IBOutlet weak var btnLogInOut: UIBarButtonItem!
	
	deinit {
		print("Deinit Application View Controller")
	}
	
	// MARK: - Application Updating
	
	func getApplications(_ sender: UIRefreshControl) {
		
		// If we're in online mode (ie. we have a connection to the pulser server)
		if Network.IsOnline {
			btnLogInOut.title = "Logout"
			// Make a request to the applications route to get all applications and their updates
			Network.requestJSON("/api/applications", method: .GET, body: nil).then { res -> Promise<[Application]> in
				self.applications_previous = self.applications
				
				// First, remove all the applications in the array.
				self.applications.removeAll()
				
				let data = res["data"] as! [[String:Any]]
				
				// Firstly delete all the applications and updates from the Core Data
				CDApplication.deleteAll(CDApplication.self)
				CDUpdate.deleteAll(CDApplication.self)
				
				return when(fulfilled: data.map { element -> Promise<Application> in
					
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
					
					// Create all the Core Data updates
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

						let cd_image: CDImage = has_cd_image ?? CDImage.insert()

						cd_image.app_slug = app_slug
						cd_image.application = cd_app

						// Download the image data from the server
						return Network.request(app_image, method: .GET, body: nil).then { img_data -> Promise<Application> in
							// Set the image's data to what was downloaded
							cd_image.data = img_data
							print("Downloaded Image (\(cd_image.data?.count))")
							cd_app.image = cd_image
							app.cd_image = cd_image

							return Promise(value: app)
						}
					} else {
						// However, if there was an image, we'll set it and update the UIImage
						print ("There was an image! (for application: \(cd_app.slug), size: \(has_cd_image?.data?.count))")
						has_cd_image?.application = cd_app
						cd_app.image = has_cd_image
						app.cd_image = has_cd_image

						return Promise(value: app)
					}
				})
			}.then { apps -> Promise<()> in
				self.applications = apps
				
				// The main body of text when creating a notification (if any)
				var notification_body = ""
				
				// After adding all the applications to the applications array
				// we must loop through them all to detect for new updates
				// (There *must* be a more efficient way to do this, surely?)
				
				for application_new in self.applications {
					// Asynchronously update the UIImage in the application
					application_new.updateImage()
					
					for application_old in self.applications_previous {
						if application_new.slug == application_old.slug {
							let set_new: Set<Module> = Set(application_new.updates)
							let set_old: Set<Module> = Set(application_old.updates)
							let result = set_new.subtracting(set_old)
							for upd in result {
								notification_body += application_new.name + ": " + upd.text + " (" + Date(timeIntervalSince1970: TimeInterval(upd.timestamp)).timeAgoSinceNow()
								if upd.value > 0 {
									notification_body += ", " + String(upd.value) + "%"
								}
								if upd.urgency == "high" {
									notification_body += ", high priority"
								}
								notification_body += ")\n"
							}
							break
						}
					}
				}
				
				if notification_body != "" {
					Notifications.create(notification_body)
				}
				
				return Promise(value: ())
			}.catch { _ in
				Network.alert("Server Error", message: "Couldn't get a list of applications from the server", viewController: self)
				Network.IsOnline = false
			}.always {
				CDImage.emptyUnused(self.applications)
				CoreDataManager.saveContext()
				
				// After everything is finished, reload the table
				self.reloadTable()
				sender.endRefreshing()
			}
		} else {
			btnLogInOut.title = "Log In"
			applications.removeAll()
			
			applications = Application.fromCoreData()
			
			sender.endRefreshing()
			self.reloadTable()
			
			Network.alert("Offline Mode", message: NetworkErrorEnum.coredata.rawValue, viewController: self)
		}
	}
	
	func reloadTable() {
		applications = Application.sort(applications)
		self.tableView.reloadData()
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
	
	func updateTimer() {
		if Network.IsOnline {
			if let interval_string = Preferences.get("update_frequency") {
				let timer_interval: Int = Int(interval_string)!
				
				print ("")
				print ("User preferences changed!", timer_interval)
				
				switch timer_interval {
				case 1 ..< Int.max:
					print ("Timer has been set for \(timer_interval * 60) seconds")
					timer = Timer.scheduledTimer(timeInterval: Double(timer_interval * 60), target: self, selector: #selector(ApplicationTableViewController.handleTimer), userInfo: nil, repeats: true)
					break
				default:
					removeTimer()
					break
				}
			}
		} else {
			removeTimer()
		}
	}
	
	func removeTimer() {
		if let timer = self.timer {
			timer.invalidate()
		}
		self.timer = nil
	}
	
	func handleTimer() {
		getApplications(self.refreshControl!)
	}
	
	// MARK: - Button Methods
	
	@IBAction func btnSettingsClick(_ sender: UIBarButtonItem) {
		let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
		if let url = settingsUrl {
			// When the button is clicked, open the settings page for this app
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
		}
	}
	
	// MARK: - View Load

    override func viewDidLoad() {
        super.viewDidLoad()
		
		getApplications(self.refreshControl!)
		refreshControl?.addTarget(self, action: #selector(ApplicationTableViewController.getApplications(_:)), for: UIControlEvents.valueChanged)
		
		// Create an observer so that the fields are updated automatically as they are changed
		NotificationCenter.default.addObserver(self,
		    selector: #selector(ApplicationTableViewController.updateTimer),
		    name: UserDefaults.didChangeNotification,
		    object: nil)
		
		updateTimer()
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
		// These settings allow for rounded images
		cell.imgAppImage.layer.masksToBounds = false
		cell.imgAppImage.layer.cornerRadius = 6.0
		cell.imgAppImage.clipsToBounds = true

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
	override func viewWillDisappear(_ animated: Bool) {
		if exitToLogin {
			NotificationCenter.default.removeObserver(self)
			removeTimer()
			if Network.IsOnline {
				Preferences.set("login_token", value: "")
				Preferences.set("login_username", value: "")
			}
			print("Removing observer, setting timer to nil, and resetting preferences")
		}
	}

}
