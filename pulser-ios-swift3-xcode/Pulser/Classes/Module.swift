//
//  Module.swift
//  Pulser
//
//  Created by Tom Gardiner on 09/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit

class Module {
	var text: String
	var value: Float
	var state: String
	var urgency: String
	var timestamp: Int
	var image: UIImage
	var objectid: String
	
	internal func state(_ state: String) {
		self.state = state
		self.image = UIImage(named: "state_" + self.state)!
	}
	
	init?(text: String, value: Float?, state: String, urgency: String, timestamp: Int, id: String) {
		self.text = text
		self.state = state
		self.urgency = urgency
		self.timestamp = timestamp
		self.objectid = id
		
		if let value_nil = value {
			self.value = value_nil
		} else {
			self.value = 0
		}
		
		self.image = UIImage(named: "state_" + self.state)!
	}
	
	static func parseUpdates(_ updates: [[String: Any]]?) -> [Module] {
		var updates_array = [Module]()
		for (_, update) in updates!.enumerated() {
			let mod_text      = update["text"] as! String
			let mod_value     = NSString(string: update["value"] as! String).floatValue
			let mod_state     = update["state"] as! String
			let mod_urgency   = update["urgency"] as! String
			let mod_id        = update["_id"] as! String
			let mod_timestamp = update["timestamp"] as! Int
			
			let mod = Module(text: mod_text, value: mod_value, state: mod_state, urgency: mod_urgency, timestamp: mod_timestamp, id: mod_id)
			
			updates_array.append(mod!)
		}
		
		// Sort the updates by timestamp, so the most recent always appears at the top
		updates_array = sortUpdates(updates_array)
		
		return updates_array
	}
	
	static func sortUpdates(_ updates: [Module]) -> [Module] {
		return updates.sorted(by: { $0.timestamp > $1.timestamp })
	}
}
