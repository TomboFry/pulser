//
//  ModuleTableViewController.swift
//  Pulser
//
//  Created by Tom Gardiner on 06/11/2016.
//  Copyright © 2016 TomboFry. All rights reserved.
//

import UIKit

class ModuleTableViewController: UITableViewController {
	
	@IBOutlet var refresher: UIRefreshControl!
	
	deinit { //Not needed for iOS9 and above. ARC deals with the observer.
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	// An array of modules that contain the information required to display
	var modules = [Module]()
	var modules_previous = [Module]()
	
	var io: SocketIOClient?
	
	// Access the App Delegate for a shared ServerController class between View Controllers
	let del = UIApplication.sharedApplication().delegate as! AppDelegate
	// Used to keep track of the module we're about to delete
	var deleteModuleIndexPath: NSIndexPath? = nil
	
	var SwiftTimer: NSTimer = NSTimer()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound, .Badge], categories: nil)
		UIApplication.sharedApplication().registerUserNotificationSettings(settings)
		UIApplication.sharedApplication().applicationIconBadgeNumber = 0
		
		// Set up the refresh control
		self.refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
		self.refresher.addTarget(self, action: #selector(ModuleTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
		
		let appDefaults = [String:AnyObject]()
		NSUserDefaults.standardUserDefaults().registerDefaults(appDefaults)
		
		// Create an observer so that the fields are updated automatically as they are changed
		NSNotificationCenter.defaultCenter().addObserver(self,
		                                                 selector: #selector(ModuleTableViewController.updateTimer),
		                                                 name: NSUserDefaultsDidChangeNotification,
		                                                 object: nil)
		
		// Create a timer to automatically refresh the database every
		// number of minutes the user it set to
		updateTimer()
		
	}
	
	func socketConnect() {
		io = SocketIOClient(socketURL: NSURL(string: "http://\(del.api.server_url)")!)
		
		io!.on("module-update") { (data, ack) in
			let name = data[0].valueForKey("name") as! String
			let value = (data[0].valueForKey("value") as? NSString)!.floatValue
			let text = data[0].valueForKey("text") as! String
			let state = data[0].valueForKey("state") as! String
			let timestamp = data[0].valueForKey("timestamp") as! Int
			
			//print ("New Values: \(name); \(value); \(text); \(state); \(timestamp)")
			
			var existing = false
			var made_change = false
			for (mod) in self.modules {
				if mod.name == name {
					existing = true
					//print ("Old Values: \(mod.name); \(mod.value); \(mod.text); \(mod.state); \(mod.timestamp)")
					if mod.state != state || mod.text != text || mod.value != value {
						mod.state(state)
						mod.text = text
						mod.value = value
						mod.timestamp = timestamp
						made_change = true
					}
				}
			}
			if existing == false {
				self.modules += [Module(name: name, text: text, value: value, state: state, timestamp: timestamp)!]
			}
			if existing == false || (existing == true && made_change == true) {
				self.createNotification("\(name): \(text) (\(value)%% - \(state))\n", badge: 1);
			}
			
			// Once the data has been retrieved
			// Asychronously update/reload the table view to reflect the changes
			dispatch_async(dispatch_get_main_queue(), {
				self.reloadTable()
			})
			
		}
		
		//io!.onAny { (evt) in
		//	print (evt)
		//}
		
		io!.connect()
	}
	
	func socketDisconnect() {
		if io != nil {
			io!.disconnect()
		}
	}
	
	// When the table view is refreshed get the data with the refresh control passed in
	func handleRefresh(refreshControl: UIRefreshControl) {
		getData(refreshControl)
	}
	
	internal func updateTimer() {
		if del.api.refresh_time > 0 {
			// Invalidate all existing refreshing methods
			SwiftTimer.invalidate()
			socketDisconnect()
			
			// Create a new timer
			SwiftTimer = NSTimer.scheduledTimerWithTimeInterval(Double(del.api.refresh_time) * 60, target:self, selector: #selector(ModuleTableViewController.handleTimerUpdate), userInfo: nil, repeats: true)
		} else if del.api.refresh_time == -1 {
			// Invalidate the existing timer
			SwiftTimer.invalidate()
			
			// Connect to the websocket
			socketConnect()
		} else {
			// If we have notifications turned off, invalidate both.
			SwiftTimer.invalidate()
			socketDisconnect()
		}
		
		refreshControl?.beginRefreshing()
		getData(refreshControl)
	}
	
	func handleTimerUpdate(timer: NSTimer){
		getData()
	}
	
	// Gets the module data from the Node server and adds the relevant table cells
	func getData(refreshControl: UIRefreshControl? = nil) {
		print("Getting new data...")
		print (NSDate.init(timeIntervalSinceNow: 0))
		
		// Reset the list of modules, so we don't just add more
		self.modules_previous = self.modules
		self.modules = []
		
		// Make a GET request to the server at page "/modules"
		del.api.makeRequest("/modules", method: "GET", body: nil) { (data, err) in
			// Asynchronously update the UI, disabling the refresh control
			dispatch_async(dispatch_get_main_queue(), {
				if refreshControl != nil {
					refreshControl?.endRefreshing()
				}
			})
			// If there was an error, display a message to the user
			if err != nil {
				self.gotoSettings()
			} else {
				// If we successfully got data from the server,
				// Loop through each one
				for (_, element) in data["data"].enumerate() {
					// And get the name, text and value from the JSON
					let name = element.1["name"].stringValue
					let text = element.1["text"].stringValue
					let value = element.1["value"].floatValue
					let state = element.1["state"].stringValue
					let timestamp = element.1["timestamp"].intValue
					print("Values: ", name, text, value, state)
					// Create a module with this information
					let mod = Module(name: name, text: text, value: value, state: state, timestamp: timestamp)!
					// and add it to the array of modules
					self.modules += [mod]
				}
				
				var module_diff = [Module]()
				var notification_body = ""
				for (mod) in self.modules {
					var same = false
					for (mod_prev) in self.modules_previous {
						if mod.name == mod_prev.name && mod.text == mod_prev.text && mod.state == mod_prev.state && mod.value == mod_prev.value {
							same = true
						}
					}
					if !same {
						notification_body += "\(mod.name): \(mod.text) (\(mod.value)%% - \(mod.state))\n"
						module_diff += [mod]
					}
				}
				
				if module_diff.count > 0 {
					self.createNotification(notification_body, badge: module_diff.count);
				}
				
				dispatch_async(dispatch_get_main_queue(), {
					self.reloadTable()
				})
			}
		}
	}
	
	func reloadTable() {
		// Sort the modules by timestamp, so the most recent always appears at the top
		modules.sortInPlace({ $0.timestamp > $1.timestamp })
		
		// Once the data has been retrieved
		// Asychronously update/reload the table view to reflect the changes
		self.tableView.reloadData()
	}
	
	func createNotification(body: String, badge: Int) {
		let localNotification = UILocalNotification()
		localNotification.fireDate = NSDate(timeIntervalSinceNow: 1)
		localNotification.alertBody = body
		localNotification.applicationIconBadgeNumber += badge
		
		UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
	}
	
	func gotoSettings() {
		dispatch_async(dispatch_get_main_queue(), {
			// Create an alert controller
			let alert = UIAlertController(title: "Update Failed", message: "Pulser was not able to connect to the server. Please update your connection settings", preferredStyle: UIAlertControllerStyle.Alert)
			
			// Create a "Settings" button
			let settingsAction = UIAlertAction(title: "Go to Settings", style: .Default) { (_) in
				let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
				if let url = settingsUrl {
					// When the button is clicked, open the settings page for this app
					UIApplication.sharedApplication().openURL(url)
				}
			}
			
			// Add the settings button and a cancel button that just closes the window
			alert.addAction(settingsAction)
			alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
			
			// Display the alert
			self.presentViewController(alert, animated: true, completion: nil)
		})
	}
	
	func popup(title: String, message: String) {
		dispatch_async(dispatch_get_main_queue(), {
			// Create an alert controller
			let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
			alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
			
			// Display the alert
			self.presentViewController(alert, animated: true, completion: nil)
		})
	}
	
	func confirmDelete(rowNum: Int) {
		let module = modules[rowNum]
		let alert = UIAlertController(title: "Remove Module", message: "Are you sure you want to permanently delete \(module.name)?", preferredStyle: .ActionSheet)
		
		let DeleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: handleDelete)
		let CancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {(alert: UIAlertAction) in
			self.deleteModuleIndexPath = nil
		})
		
		alert.addAction(DeleteAction)
		alert.addAction(CancelAction)
		
		// Support display in iPad
		alert.popoverPresentationController?.sourceView = self.view
		alert.popoverPresentationController?.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0)
		
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	func handleDelete(alertAction: UIAlertAction!) {
		if let indexPath = deleteModuleIndexPath {
			let module = modules[indexPath.row]
			del.api.makeRequest("/modules/" + module.name, method: "DELETE", body: nil, onCompletion: {_,err in
				if err != nil {
					self.gotoSettings()
				} else {
					dispatch_async(dispatch_get_main_queue(), {
						self.tableView.beginUpdates()
						self.modules.removeAtIndex(indexPath.row)
						self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
						self.deleteModuleIndexPath = nil
						self.tableView.endUpdates()
						self.reloadTable()
					})
				}
			})
		}
	}
	
	@IBAction func settingsBtn(sender: UIBarButtonItem) {
		let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
		if let url = settingsUrl {
			// When the button is clicked, open the settings page for this app
			UIApplication.sharedApplication().openURL(url)
		}
	}
	
	@IBAction func logoutBtn(sender: UIBarButtonItem) {
		NSUserDefaults.standardUserDefaults().setValue("", forKey: "login_token")
		dispatch_async(dispatch_get_main_queue(), {
			self.performSegueWithIdentifier("logout_segue", sender: nil)
		})
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	

	// MARK: - Table view data source

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	// When the number of rows is asked for, return the number of modules loaded
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return modules.count
	}

	// When adding the table rows, include the information from each index in the modules array.
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		// Create a table view cell with the custom Module type
		let cell = tableView.dequeueReusableCellWithIdentifier("ModuleTableViewCell", forIndexPath: indexPath) as! ModuleTableViewCell
		
		let module = modules[indexPath.row]
		
		cell.nameLabel.text = module.name
		cell.txtLabel.text = module.text
		cell.stateImage.image = module.image
		cell.valueProgress.progress = module.value / 100
		
		return cell
	}

	// Override to support conditional editing of the table view.
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}

	// Allow the user to remove modules from the list AND server
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		// If we're deleting the row
		if editingStyle == .Delete {
			deleteModuleIndexPath = indexPath
			confirmDelete(indexPath.row)
		}
	}

	/*
	// Override to support rearranging the table view.
	override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

	}
	*/

	/*
	// Override to support conditional rearranging of the table view.
	override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		// Return false if you do not want the item to be re-orderable.
		return true
	}
	*/

	/*
	// MARK: - Navigation

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
	}
	*/

}
