//
//  Module.swift
//  Pulser
//
//  Created by Tom Gardiner on 09/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit

class Module: Hashable {
	var text: String
	var value: Float
	var state: String
	var urgency: String
	var timestamp: Int
	var image: UIImage
	var objectid: String
	
	var hashValue: Int {
		return self.objectid.characters.count
	}
	
	internal func state(_ state: String) {
		self.state = state
		self.image = UIImage(named: "state_" + self.state)!
	}
	
	init(text: String, value: Float, state: String, urgency: String, timestamp: Int, id: String) {
		self.text = text
		self.state = state
		self.urgency = urgency
		self.timestamp = timestamp
		self.objectid = id
		self.value = value
		
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
			
			updates_array.append(mod)
		}
		
		// Sort the updates by timestamp, so the most recent always appears at the top
		updates_array = sortUpdates(updates_array)
		
		return updates_array
	}
	
	static func sortUpdates(_ updates: [Module]) -> [Module] {
		return updates.sorted(by: { $0.timestamp > $1.timestamp })
	}
	
	static func fromCoreData(_ app_elm: CDApplication) -> [Module] {
		
		let cd_updates = app_elm.updates?.allObjects as! [CDUpdate]
		var updates: [Module] = []
		
		// Create the actual update/module instances
		for upd in cd_updates {
			updates.append(Module(text: upd.text, value: upd.value, state: upd.state, urgency: upd.urgency, timestamp: Int(upd.timestamp), id: upd.objectid))
		}
		
		return self.sortUpdates(updates)
	}
	
	static func fromCoreData(with slug: String) -> [Module] {
		let cd_updates: [CDUpdate] = CDUpdate.fetchAll()
		var updates: [Module] = []
		
		// Create the actual update/module instances
		for upd in cd_updates {
			if (upd.application?.slug == slug) {
				updates.append(Module(text: upd.text, value: upd.value, state: upd.state, urgency: upd.urgency, timestamp: Int(upd.timestamp), id: upd.objectid))
			}
		}
		
		return self.sortUpdates(updates)
	}
}

func ==(lhs: Module, rhs: Module) -> Bool {
	return lhs.objectid == rhs.objectid
}
