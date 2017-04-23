//
//  Network.swift
//  Pulser
//
//  Created by Tom Gardiner on 08/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

public typealias JSON = Dictionary<String, Any>

public struct NetworkError: Error {
	public var localizedDescription: String
}

public enum NetworkErrorEnum: String {
	case connect = "Could not connect to the server."
	case coredata = "Using offline data"
	case password = "Password incorrect"
	case username = "User does not exist"
}

class Network {
	
	public enum Method: String {
		case GET, POST, PUT, DELETE
	}
	
	private static var isOnline = true
	
	public static var IsOnline: Bool {
		get { return self.isOnline }
		set {
			self.isOnline = newValue
			
			if self.isOnline {
				CoreDataManager.deleteOnSync({ () -> (Void) in })
			}
		}
	}
	
	static func request(_ path: String, method: Method, body: JSON?) -> Promise<Data> {
		let full_path = Preferences.get("login_server")! + path
		
		if let path_format: String = encodeURL(full_path) {
			print("") // New line for neatness
			print(path_format, "(\(method.rawValue))")
			
			// Create URL Request
			var request = URLRequest(url: URL(string: path_format)!)
			
			// Set request HTTP method to GET. It could be POST as well
			request.httpMethod = method.rawValue
			
			if body != nil {
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")
				request.httpBody = try? JSONSerialization.data(withJSONObject: body!, options: [])
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
			
			// Execute HTTP Request
			return Promise { fulfill, reject in
				URLSession.shared.dataTask(with: request) {
					data, response, error in
					// Check for error
					if error != nil || data == nil {
						print("Server Response: \(error!.localizedDescription)")
						reject(NetworkError(localizedDescription: error!.localizedDescription))
					} else {
						fulfill(data!)
					}
				}.resume()
			}
		} else {
			return Promise(error: NetworkError(localizedDescription: "For some reason, we weren't able to connect. Either there's a problem with the URL you provided, or it's just having trouble connecting."))
		}
	}
	
	static func requestJSON(_ path: String, method: Method, body: JSON?) -> Promise<JSON> {
		return request(path, method: method, body: body).then { data -> Promise<JSON> in
			// Convert server json response to NSDictionary
			if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? JSON {
				if dict["status"] as! String == "error" {
					return Promise(error: NetworkError(localizedDescription: dict["data"] as! String))
				} else {
					return Promise(value: dict)
				}
			} else {
				return Promise(error: NetworkError(localizedDescription: "Could not parse response from server"))
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
		let urlRegEx = "^(?:(?:https?|ftp)://)(?:\\S+(?::\\S*)?@)?(?:(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)(?:\\.(?:[a-z\\u00a1-\\uffff0-9]-*)*[a-z\\u00a1-\\uffff0-9]+)*(?:\\.(?:[a-z\\u00a1-\\uffff]{2,}))\\.?)(?::\\d{2,5})?(?:[/?#]\\S*)?$"
		let canopen = NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: url)
		return canopen
	}
	
	static func alert(_ title: String, message: String, viewController vc: UIViewController?) {
		// Create an alert controller
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
		
		// Add the settings button and a cancel button that just closes the window
		alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
		
		// Display the alert
		var viewController = UIApplication.shared.keyWindow?.rootViewController
		if vc != nil {
			viewController = vc
		}
		viewController?.present(alert, animated: true, completion: nil)
	}
}
