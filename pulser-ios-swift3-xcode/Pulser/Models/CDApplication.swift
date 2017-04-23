//
//  CDApplication+CoreDataClass.swift
//  Pulser
//
//  Created by Tom Gardiner on 17/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation
import CoreData

public class CDApplication: NSManagedObject {

}

extension CDApplication {
	
	@NSManaged public var name: String
	@NSManaged public var slug: String
	@NSManaged public var image: CDImage?
	@NSManaged public var updates: NSSet?
	
	// MARK: Generated accessors for updates
	
	@objc(addUpdatesObject:)
	@NSManaged public func addToUpdates(_ value: CDUpdate)
	
	@objc(removeUpdatesObject:)
	@NSManaged public func removeFromUpdates(_ value: CDUpdate)
	
	@objc(addUpdates:)
	@NSManaged public func addToUpdates(_ values: NSSet)
	
	@objc(removeUpdates:)
	@NSManaged public func removeFromUpdates(_ values: NSSet)
	
}
