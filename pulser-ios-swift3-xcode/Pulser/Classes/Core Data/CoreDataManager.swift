//
//  CoreDataManager.swift
//  Pulser
//
//  Created by Tom Gardiner on 16/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CoreDataManager: NSObject {
	
	private class func getContext() -> NSManagedObjectContext {
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		return appDelegate.persistentContainer.viewContext
	}
	
	class func storeApplication(slug: String, name: String) {
		let context = getContext()
		
		let entity = NSEntityDescription.entity(forEntityName: "CD_Application", in: context)
		
		let managedObj = NSManagedObject(entity: entity!, insertInto: context)
		
		//managedObj.setValue(")
	}
	
}
