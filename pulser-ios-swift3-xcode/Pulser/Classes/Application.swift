//
//  Application.swift
//  Pulser
//
//  Created by Tom Gardiner on 13/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import UIKit

class Application {
	
	var slug: String
	var name: String
	var cd_image: CDImage?
	var image: UIImage?
	var updates: [Module]
	
	init (slug: String, name: String, image: CDImage?, updates: [Module]) {
		self.slug = slug
		self.name = name
		self.updates = updates
		self.image = nil
		self.cd_image = image
		if self.cd_image != nil {
			print("Application Init:  CDImage Exists = \(self.cd_image != nil)")
			print(" - CDImage Data Exists = \(self.cd_image?.data != nil)")
			self.updateImage()
		}
	}
	
	func updateImage() {
		DispatchQueue.main.async {
			if self.cd_image != nil && self.cd_image?.data != nil {
				self.image = UIImage(data: (self.cd_image?.data)!)
			}
		}
	}
	
	static func sort(_ applications: [Application]) -> [Application] {
		return applications.sorted(by: { (a, b) -> Bool in
			var timestamp_a = 0;
			var timestamp_b = 0;
			
			if (a.updates.count > 0) {
				timestamp_a = a.updates[0].timestamp;
			}
			if (b.updates.count > 0) {
				timestamp_b = b.updates[0].timestamp;
			}
			return timestamp_a > timestamp_b
		})
	}
	
	static func fromCoreData() -> [Application] {
		var applications: [Application] = []
		// If we're in offline mode, get the information from Core Data instead
		let apps: [CDApplication] = CDApplication.fetchAll()
		for app_elm in apps {
			
			// Get both the updates in an application, and the image if there is one
			let cd_image = app_elm.image as CDImage?
			
			let updates = Module.fromCoreData(app_elm)
			
			// Finally, convert it all into an Application instance and append it to the array
			applications.append(Application(slug: app_elm.slug, name: app_elm.name, image: cd_image, updates: Module.sortUpdates(updates)))
		}
		return applications
	}
	
}
