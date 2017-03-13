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
	
	internal func state(_ state: String) {
		self.state = state
		self.image = UIImage(named: "state_" + self.state)!
	}
	
	init?(text: String, value: Float?, state: String, urgency: String, timestamp: Int) {
		self.text = text
		self.state = state
		self.urgency = urgency
		self.timestamp = timestamp
		
		if let value_nil = value {
			self.value = value_nil
		} else {
			self.value = 0
		}
		
		self.image = UIImage(named: "state_" + self.state)!
	}
}
