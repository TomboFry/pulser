//
//  Preferences.swift
//  Pulser
//
//  Created by Tom Gardiner on 08/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation

class Preferences {
	
	public static func get(_ key: String) -> String? {
		if let value = UserDefaults.standard.string(forKey: key) {
			return value
		}
		return nil
	}
	
	public static func set(_ key: String, value: String) {
		UserDefaults.standard.setValue(value, forKey: key)
	}
	
}
