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
	
}
