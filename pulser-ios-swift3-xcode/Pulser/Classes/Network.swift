//
//  Network.swift
//  Pulser
//
//  Created by Tom Gardiner on 08/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation
import UIKit

public typealias JSONResponse = (Dictionary<String, Any>?, String?) -> Void
public typealias DataResponse = (Data?, String?) -> Void

class Network {
	
	public enum Method: String {
		case GET, POST, PUT, DELETE
	}
	
	static func request(_ path: String, method: Method, body: Dictionary<String, Any>?, onCompletion: @escaping DataResponse) {
		let full_path = Preferences.get("login_server")! + path
		
		if let path_format: String = encodeURL(full_path) {
			print("") // New line for neatness
			print(path_format)
			
			// Creaste URL Request
			var request = URLRequest(url: URL(string: path_format)!)
			
			// Set request HTTP method to GET. It could be POST as well
			request.httpMethod = method.rawValue
			
			if body != nil {
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")
				request.httpBody = try? JSONSerialization.data(withJSONObject: body!, options: [])
				print(body!)
			}
			
			// If needed you could add Authorization header value
			// Add Basic Authorization
			if let token = Preferences.get("login_token") {
				let username = Preferences.get("login_username")!
				let loginString = NSString(format: "%@:%@", username, token)
				let loginData: Data = loginString.data(using: String.Encoding.utf8.rawValue)!
				let base64LoginString = "Basic " + loginData.base64EncodedString(options: [])
				request.addValue(base64LoginString, forHTTPHeaderField: "Authorization")
			}
			
			// Excute HTTP Request
			URLSession.shared.dataTask(with: request) {
				data, response, error in
				
				// Check for error
				if error != nil
				{
					return onCompletion(nil, (error?.localizedDescription)!)
				}
				
				// Print out response string
				let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
				print("responseString = \(responseString)")
				
				return onCompletion(data, nil)
			}.resume()
		} else {
			return onCompletion(nil, "For some reason, we weren't able to connect. Either there's a problem with the URL you provided, or it's just having trouble connecting.")
		}
	}
	
	static func requestJSON(_ path: String, method: Method, body: Dictionary<String, Any>?, onCompletion: @escaping JSONResponse) {
		
		request(path, method: method, body: body) { (data, err) in
			if data != nil && err == nil {
				// Convert server json response to NSDictionary
				do {
					if let dict = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any> {
						return onCompletion(dict, nil)
					} else {
						return onCompletion(nil, "Could not parse response from server")
					}
				} catch let error as NSError {
					return onCompletion(nil, error.localizedDescription)
				}
			} else {
				return onCompletion(nil, err)
			}
		}
		
	}
	
	static func encodeURL(_ url: String) -> String? {
		var path = (url.removingPercentEncoding?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)!
		if !path.hasPrefix("http") {
			path = "http://" + path
		}
		
		return validateUrl(path) ? path : nil
	}
	
	private static func validateUrl(_ url: String) -> Bool {
		/*if let nsurl = NSURL(string: url) {
			let canopen = UIApplication.shared.canOpenURL(nsurl as URL)
			print("Can opener", canopen)
			return canopen
		}*/
		
		//let urlRegEx = "(?:(?:https?|ftp|file):\\/\\/|www\\.|ftp\\.)(?:\\([-A-Z0-9+&@#\\/%=~_|$?!:,.]*\\)|[-A-Z0-9+&@#\\/%=~_|$?!:,.])*(?:\\([-A-Z0-9+&@#\\/%=~_|$?!:,.]*\\)|[A-Z0-9+&@#\\/%=~_|$])"
		let urlRegEx = "^(?:(?:https?|ftp)://)(?:\\S+(?::\\S*)?@)?(?:(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)(?:\\.(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)*(?:\\.(?:[a-z\\u00a1-\\uffff]{2,}))\\.?)(?::\\d{2,5})?(?:[/?#]\\S*)?$"
		let canopen = NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: url)
		print("Can the can opener open the openable can?", canopen)
		return canopen
	}
	
	static func alert(_ title: String, message: String) {
		DispatchQueue.main.async(execute: {
			// Create an alert controller
			let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
			
			// Add the settings button and a cancel button that just closes the window
			alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
			
			// Display the alert
			UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
		})
	}
}
