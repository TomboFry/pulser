//
//  Module.swift
//  Pulser
//
//  Created by Tom Gardiner on 06/11/2016.
//  Copyright © 2016 TomboFry. All rights reserved.
//

import UIKit

class Module {
	
	// MARK: Properties
	var name: String
	var text: String
	var value: Float
	var state: String
	var urgency: String
	var timestamp: Int
	var image: UIImage
	
	internal func state(state: String){
		self.state = state
		self.image = UIImage(named: "state_" + self.state)!
	}
	
	// MARK: Initialization
	init ?(name: String, text: String, value: Float!, state: String, urgency: String, timestamp: Int) {
		self.name = name
		self.text = text
		self.state = state
		self.urgency = urgency
		self.timestamp = timestamp
		
		if name.isEmpty {
			return nil
		}
		
		if let value_nil = value {
			self.value = value_nil
		} else {
			self.value = 0
		}
		
		self.image = UIImage(named: "state_" + self.state)!
	}
}