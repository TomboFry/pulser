//
//  CDUpdate+CoreDataClass.swift
//  Pulser
//
//  Created by Tom Gardiner on 17/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation
import CoreData


public class CDUpdate: NSManagedObject {

}

extension CDUpdate {
	
	@NSManaged public var text: String?
	@NSManaged public var value: Float
	@NSManaged public var state: String?
	@NSManaged public var urgency: String?
	@NSManaged public var objectid: String?
	@NSManaged public var timestamp: Int32
	@NSManaged public var application: CDApplication?
	
}
