//
//  LoginViewController.swift
//  Pulser
//
//  Created by Tom Gardiner on 14/11/2016.
//  Copyright © 2016 TomboFry. All rights reserved.
//

import UIKit

typealias LoginResponse = (JSON, NSError?) -> Void

class LoginViewController: UIViewController {
	
	var serverUrlTxtInitial = ""
	
	//var values: NSDictionary = [:]
	var values: JSON = [];
	
	@IBOutlet weak var serverUrlTxt: UITextField!
	@IBOutlet weak var usernameTxt: UITextField!
	@IBOutlet weak var passwordTxt: UITextField!
	@IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
	@IBOutlet weak var buttonLogin: UIButton!
	@IBOutlet weak var buttonRegister: UIButton!
	@IBOutlet weak var buttonCancel: UIButton!
	
	// Access the App Delegate for a shared ServerController class between View Controllers
	let del = UIApplication.sharedApplication().delegate as! AppDelegate
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Check if we have a token and make sure it's still valid
		// Then change straight to the modules page if so
		if let token = NSUserDefaults.standardUserDefaults().stringForKey("login_token") {
			if !token.isEmpty {
				loadStart()
				del.api.makeRequest("/auth", method: "GET", body: nil, onCompletion: {(data, err) in
					self.loadEnd()
					if err == nil && data["status"] == "success" {
						self.gotoModules()
					}
				})
			}
		}
		
		if let url = NSUserDefaults.standardUserDefaults().stringForKey("server_url_preference") {
			serverUrlTxt.text = url
			serverUrlTxtInitial = url
		}
		if let username = NSUserDefaults.standardUserDefaults().stringForKey("login_username") {
			usernameTxt.text = username
		}
	}
	
	func loadStart() {
		loadingIndicator.startAnimating()
		
		buttonLogin.enabled = false
		buttonLogin.hidden = true
		
		buttonRegister.enabled = false
		buttonRegister.hidden = true
		
		buttonCancel.enabled = true
		buttonCancel.hidden = false
	}
	
	func loadEnd() {
		loadingIndicator.stopAnimating()
		
		buttonLogin.enabled = true
		buttonLogin.hidden = false
		
		buttonRegister.enabled = true
		buttonRegister.hidden = false
		
		buttonCancel.enabled = false
		buttonCancel.hidden = true
	}
	
	func validateInput() -> Bool {
		var valid = false
		
		if let url = serverUrlTxt.text {
			if url != serverUrlTxtInitial {
				NSUserDefaults.standardUserDefaults().setValue(url, forKey: "server_url_preference")
				valid = true
			}
		}
		
		if usernameTxt.text != nil && passwordTxt.text != nil {
			valid = true
		}
		
		values = JSON(["username": usernameTxt.text!, "password": passwordTxt.text!])
		
		return valid
		
	}
	
	func loginFailed(title: String, message: String) {
		dispatch_async(dispatch_get_main_queue(), {
			// Create an alert controller
			let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
			
			// Add the settings button and a cancel button that just closes the window
			alert.addAction(UIAlertAction(title: "Okey dokey", style: .Cancel, handler: nil))
			
			// Display the alert
			self.presentViewController(alert, animated: true, completion: nil)
		})
	}
	
	func validateLogin(url: String, onSuccess: LoginResponse) {
		if !validateInput() { return }
		
		loadStart()
		
		del.api.makeRequest(url, method: "POST", body: values, onCompletion: {(data, err) in
			self.loadEnd()
			if err != nil {
				self.loginFailed("Login Failed", message: "Could not login")
			}
			if data["status"].stringValue == "error" {
				self.loginFailed("Login Failed", message: data["data"].stringValue)
			} else {
				onSuccess(data, err)
			}
		})
	}
	
	func gotoModules() {
		dispatch_async(dispatch_get_main_queue(), {
			self.performSegueWithIdentifier("modules_segue", sender: nil)
		})
	}
	
	@IBAction func loginBtn(sender: UIButton) {
		validateLogin("/login", onSuccess: {(data, err) in
			NSUserDefaults.standardUserDefaults().setValue(self.usernameTxt.text, forKey: "login_username")
			NSUserDefaults.standardUserDefaults().setValue(data["data"].stringValue, forKey: "login_token")
			self.gotoModules()
		})
	}
	
	@IBAction func registerBtn(sender: UIButton) {
		validateLogin("/users", onSuccess: {(data, err) in
			self.loginBtn(sender)
		})
	}
	@IBAction func cancelBtn(sender: UIButton) {
		del.api.cancelRequest()
		loadEnd()
	}
}
