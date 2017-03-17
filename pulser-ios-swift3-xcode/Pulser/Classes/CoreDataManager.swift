//
//  CoreDataManager.swift
//  Pulser
//
//  Created by Tom Gardiner on 16/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {
	
	private init() {
		// Empty, to prevent anyone from creating an instance of it.
	}
	
	// MARK: - Core Data stack
	
	class func getContext() -> NSManagedObjectContext {
		return CoreDataManager.persistentContainer.viewContext
	}
	
	static var persistentContainer: NSPersistentContainer = {
		/*
		The persistent container for the application. This implementation
		creates and returns a container, having loaded the store for the
		application to it. This property is optional since there are legitimate
		error conditions that could cause the creation of the store to fail.
		*/
		let container = NSPersistentContainer(name: "Pulser")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				
				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()
	
	// MARK: - Core Data Saving support
	
	class func saveContext () {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
}

// MARK: - Fetching and Saving Core Data


extension NSManagedObject {

	public class func getFetchRequest<T: NSManagedObject>() -> NSFetchRequest<T> {
		return NSFetchRequest(entityName: String(describing: T.self));
	}
	
	public class func fetchAll<T: NSManagedObject>() -> [T] {
		let fetchRequest: NSFetchRequest<T> = T.getFetchRequest()
		do {
			let searchResults = try CoreDataManager.getContext().fetch(fetchRequest)
			return searchResults 
		}
		catch {
			print("Error: \(error)")
			return []
		}
	}
	
	public class func deleteAll<T: NSManagedObject>(_: T.Type) {
		let fetchRequest: NSFetchRequest<T> = T.getFetchRequest()
		do {
			let searchResults = try CoreDataManager.getContext().fetch(fetchRequest)
			for app in searchResults {
				CoreDataManager.getContext().delete(app)
			}
			CoreDataManager.saveContext()
		}
		catch {
			print("Error: \(error)")
		}
	}
	
	public class func insert<T: NSManagedObject>() -> T {
		return NSEntityDescription.insertNewObject(forEntityName: String(describing: T.self), into: CoreDataManager.getContext()) as! T
	}
	
	public class func count<T: NSManagedObject>(_: T.Type) -> Int {
		let fetchRequest: NSFetchRequest<T> = T.getFetchRequest()
		do {
			let count = try CoreDataManager.getContext().count(for: fetchRequest)
			return count
		} catch let error as NSError {
			print("Error: \(error.localizedDescription)")
			return 0
		}
	}
}
