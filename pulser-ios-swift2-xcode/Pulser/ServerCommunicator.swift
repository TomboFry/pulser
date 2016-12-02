//
//  ServerCommunicator.swift
//  Pulser
//
//  Created by Tom Gardiner on 12/11/2016.
//  Copyright © 2016 TomboFry. All rights reserved.
//

import Foundation

public typealias ServiceResponse = (JSON, NSError?) -> Void

class ServerCommunicator : NSObject {
	
	// The fields needed to connect to the pulser server
	var server_url = "", server_username = "", refresh_time = 0, notification_urgency = "low"
	private var server_token = ""
	
	deinit { //Not needed for iOS9 and above. ARC deals with the observer.
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	// Create a session
	let session = NSURLSession.sharedSession()
	
	// When the Server Communicator is first created
	override init() {
		super.init()
		
		let appDefaults = [String:AnyObject]()
		NSUserDefaults.standardUserDefaults().registerDefaults(appDefaults)
		
		// Update the fields from the preferences
		updatePrefs()
		
		// Create an observer so that the fields are updated automatically as they are changed
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: #selector(ServerCommunicator.updatePrefs),
			name: NSUserDefaultsDidChangeNotification,
			object: nil)
	}
	
	// Updates the fields
	func updatePrefs() {
		// Only update them if the value is not nil
		if let url = NSUserDefaults.standardUserDefaults().stringForKey("server_url_preference") {
			self.server_url = url
		}
		if let username = NSUserDefaults.standardUserDefaults().stringForKey("login_username") {
			self.server_username = username
		}
		if let token = NSUserDefaults.standardUserDefaults().stringForKey("login_token") {
			self.server_token = token
		}
		if let urgency = NSUserDefaults.standardUserDefaults().stringForKey("notifications_preference") {
			self.notification_urgency = urgency
		}
		
		self.refresh_time = NSUserDefaults.standardUserDefaults().integerForKey("update_freq_preference")
		
		print("Preferences updated: url-\(self.server_url), token-\(self.server_token), time-\(self.refresh_time), urg-\(self.notification_urgency)")
	}
	
	// Make a call to the node API
	internal func makeRequest(path: String, method: String, body: JSON?, onCompletion: ServiceResponse) {
		
		// Format the url as such: http://ipaddress/path
		let path_format = path.stringByReplacingOccurrencesOfString(" ", withString: "%20")
		
		let absolute_url = "http://\(self.server_url)/api\(path_format)"
		
		// Create a request
		let request = NSMutableURLRequest(URL: NSURL(string: absolute_url)!)
		
		// Set the method
		request.HTTPMethod = method
		
		// In PUT, DELETE, or POST methods, a body is usually required
		// If the body was actually set
		print (body)
		if body != nil {
			do {
				// Try to set the body of the request to that of the parameter
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")
				// Convert the passed in JSON to NSData for the HTTP body
				request.HTTPBody = try body!.rawData()
			} catch {
				print ("Error: \(error)")
			}
		}
		
		// Also send the authentication parameters to the request if they are valid
		if server_token != "" && server_username != "" {
			let loginString = NSString(format: "%@:%@", server_username, server_token)
			let loginData: NSData = loginString.dataUsingEncoding(NSUTF8StringEncoding)!
			let base64LoginString = loginData.base64EncodedStringWithOptions([])
			request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
		}
		
		print("Calling", method, absolute_url)
		
		// Make the request using the session
		let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
			var json:JSON
			
			// If there was an error, leave the json as nil
			// Otherwise set the json
			if error != nil {
				json = nil
			} else {
				json = JSON(data: data!)
			}
			// When the data has been processed, run the callback function
			onCompletion(json, error)
		})
		// Make the request and continue the session after it has been completed
		task.resume()
	}
	
	internal func cancelRequest() {
		session.invalidateAndCancel()
		print("Request cancelled")
	}
	
}