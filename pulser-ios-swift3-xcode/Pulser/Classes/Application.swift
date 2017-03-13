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
	var image: UIImage?
	var updates: [Module]
	
	init (slug: String, name: String, image_url: String?, updates: [Module]) {
		self.slug = slug
		self.name = name
		self.updates = updates
		
		if image_url != nil {
			Network.request(image_url!, method: Network.Method.GET, body: nil) { (data, err) in
				DispatchQueue.main.async {
					if data != nil {
						self.image = UIImage(data: data!)
					} else {
						self.image = nil
					}
				}
			}
		} else {
			self.image = nil
		}
	}
	
}
