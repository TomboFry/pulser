//
//  CDImages+CoreDataClass.swift
//  Pulser
//
//  Created by Tom Gardiner on 17/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation
import CoreData


public class CDImage: NSManagedObject {

}

extension CDImage {
	
	class func emptyUnused(_ applications: [Application]) {
		let fetchRequest: NSFetchRequest = CDImage.fetchRequest()
		do {
			let searchResults = try CoreDataManager.context.fetch(fetchRequest)
			for image in searchResults as! [CDImage] {
				var appExists = false
				for app in applications {
					if image.app_slug == app.slug {
						appExists = true
						break
					}
				}
				if !appExists {
					CoreDataManager.context.delete(image)
				}
			}
		}
		catch {
			print("Error: \(error)")
		}
	}
	
	@NSManaged public var data: Data?
	@NSManaged public var app_slug: String
	@NSManaged public var application: CDApplication?
	
}
