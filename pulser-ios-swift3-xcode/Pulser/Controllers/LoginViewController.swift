//
//  LoginViewController.swift
//  Pulser
//
//  Created by Tom Gardiner on 07/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit
import PromiseKit

class LoginViewController: UIViewController {
	
	@IBOutlet weak var txtServerUrl:     UITextField!
	@IBOutlet weak var txtUsername:      UITextField!
	@IBOutlet weak var txtPassword:      UITextField!
	@IBOutlet weak var btnLogin:         UIButton!
	@IBOutlet weak var btnRegister:      UIButton!
	@IBOutlet weak var btnCancel:        UIButton!
	@IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		CDImage.deleteAll(CDImage.self)
		CDUpdate.deleteAll(CDUpdate.self)
		CDApplication.deleteAll(CDApplication.self)
		CDDeleteOnSync.deleteAll(CDDeleteOnSync.self)
		
		let cd_images: [CDImage] = CDImage.fetchAll()
		var totalSize = 0
		for img in cd_images {
			if img.data != nil {
				totalSize += (img.data?.count)!
			}
		}
		print("Images:", CDImage.count(CDImage.self), "(Total Size: \(totalSize))")
		print("Updates:", CDUpdate.count(CDUpdate.self))
		print("Applications:", CDApplication.count(CDApplication.self))
		print("Delete On Sync:", CDDeleteOnSync.count(CDDeleteOnSync.self))
		
		if Preferences.get("login_token") != nil {
			Network.requestJSON("/api/auth", method: .GET, body: nil).then { result in
				self.showApplications()
			}.catch { error in
				let cd_apps: [CDApplication] = CDApplication.fetchAll()
				if cd_apps.count > 0 {
					Network.IsOnline = false
					self.showApplications()
				} else {
					Network.alert("Error occurred", message: error.localizedDescription, viewController: nil)
				}
			}
		}
		
		if let url = Preferences.get("login_server") {
			txtServerUrl.text = url
		}
		if let username = Preferences.get("login_username") {
			txtUsername.text = username
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func setButtons(_ showCancel: Bool) {
		btnLogin.isHidden = showCancel;
		btnLogin.isEnabled = !showCancel;
		
		btnRegister.isHidden = showCancel;
		btnRegister.isEnabled = !showCancel;
		
		btnCancel.isHidden = !showCancel;
		btnCancel.isEnabled = showCancel;
		
		if showCancel {
			loadingIndicator.startAnimating();
		} else {
			loadingIndicator.stopAnimating();
		}
	}
	
	func validateInput() -> Bool {
		// For the three inputs to be valid this value must reach three
		var valid_count = 0
		let valid_threshold = 3
		
		// Check the URL and encode it before setting the preference
		if let url = txtServerUrl.text {
			if let url_success = Network.encodeURL(url) {
				Preferences.set("login_server", value: url_success)
				valid_count += 1
			}
		}
		
		if let username = txtUsername.text {
			if !username.isEmpty {
				Preferences.set("login_username", value: username)
				valid_count += 1
			}
		}
		
		if let password = txtPassword.text {
			if !password.isEmpty {
				valid_count += 1
			}
		}
		
		// Make sure it's on or above the threshold to count as valid
		return valid_count >= valid_threshold ? true : false
	}
	
	func showApplications() {
		DispatchQueue.main.async {
			self.performSegue(withIdentifier: "login_complete_segue", sender: self)
		}
	}

	@IBAction func btnLoginClick(_ sender: Any) {
		setButtons(true);
		if validateInput() {
			var body: JSON = [:]
			body["username"] = txtUsername.text!
			body["password"] = txtPassword.text!
			
			Network.requestJSON("/api/login", method: .POST, body: body).then { data -> Promise<()> in
				Preferences.set("login_token", value: data["data"] as! String)
				self.showApplications()
				
				return Promise(value: ())
			}.catch { error in
				return Network.alert("Error Occurred", message: error.localizedDescription, viewController: nil)
			}.always {
				// Always hide the cancel button / activity indicator when we get a response.
				self.setButtons(false)
			}
		}
	}
	
	@IBAction func btnRegisterClick(_ sender: Any) {
		
	}
	
	@IBAction func btnCancelClick(_ sender: Any) {
		setButtons(false);
	}

}

