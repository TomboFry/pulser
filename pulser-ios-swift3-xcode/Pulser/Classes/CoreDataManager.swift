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
	
	class func deleteOnSync(_ callback: @escaping () -> (Void)) {
		// We need to make sure we actually have a network connection
		if Network.IsOnline {
			// Keep track of how many elements have been processed before running the removeCompleted function
			let totalCount = CDDeleteOnSync.count(CDDeleteOnSync.self)
			var currentCount = 0
			
			// If there are no DoS elements in Core Data, run the callback straight away, bypassing all the network stuff.
			if totalCount == 0 {
				return callback()
			}
			
			// Keep track of which DoS elements need to be removed
			var completed: [CDDeleteOnSync] = []
			
			// A function to run when the Network stuff has finished
			let removeCompleted = {
				for elm in completed {
					CoreDataManager.getContext().delete(elm)
				}
				CoreDataManager.saveContext()
				
				// Because of asynchronous network requesting a callback is needed
				// to run code when it's completed. It's not very fun...
				callback()
			}
			
			for cd_delete in CDDeleteOnSync.fetchAll() as [CDDeleteOnSync] {
				Network.requestJSON("/api/applications/\(cd_delete.app_slug)/updates/\(cd_delete.objectid)", method: Network.Method.DELETE, body: nil, onCompletion: { (data, err) in
					// Only delete the DoS element from Core Data if it was successfully removed server-side
					if (err == nil && data != nil) {
						completed.append(cd_delete)
					}
					
					currentCount += 1
					if currentCount >= totalCount {
						removeCompleted()
					}
				})
			}
		}
	}
}

// MARK: - Fetching and Saving Core Data

// Extend the Managed Object class in order to get extra functions on top of my Core Data classes
extension NSManagedObject {
	
	class func getFetchRequest<T: NSManagedObject>() -> NSFetchRequest<T> {
		return NSFetchRequest(entityName: String(describing: T.self));
	}
	
	// Return an array of all the elements in Core Data of a specific type
	public class func fetchAll<T: NSManagedObject>() -> [T] {
		let fetchRequest: NSFetchRequest<T> = T.getFetchRequest()
		do {
			return try CoreDataManager.getContext().fetch(fetchRequest)
		}
		catch {
			print("Error: \(error)")
			return []
		}
	}
	
	// Delete all elements in Core Data of a specific type
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
	
	public class func delete<T: NSManagedObject>(_ type: T.Type, key: String, value: String) {
		let fetchRequest: NSFetchRequest<T> = T.getFetchRequest()
		do {
			let searchResults = try CoreDataManager.getContext().fetch(fetchRequest)
			for app in searchResults {
				if app.value(forKey: key) as! String == value {
					CoreDataManager.getContext().delete(app)
				}
			}
			CoreDataManager.saveContext()
		}
		catch {
			print("Error: \(error)")
		}
	}
	
	// Create a new Core Data object that can be changed and applied to Core Data when context is saved
	public class func insert<T: NSManagedObject>() -> T {
		return NSEntityDescription.insertNewObject(forEntityName: String(describing: T.self), into: CoreDataManager.getContext()) as! T
	}
	
	// Return the number of elements in Core Data of a specific type
	public class func count<T: NSManagedObject>(_: T.Type) -> Int {
		let fetchRequest: NSFetchRequest<T> = T.getFetchRequest()
		do {
			return try CoreDataManager.getContext().count(for: fetchRequest)
		} catch let error as NSError {
			print("Error: \(error.localizedDescription)")
			return 0
		}
	}
}
