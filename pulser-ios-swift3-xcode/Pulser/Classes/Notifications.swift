//
//  Notifications.swift
//  Pulser
//
//  Created by Tom Gardiner on 19/03/2017.
//  Copyright © 2017 TomboFry. All rights reserved.
//

import Foundation
import UserNotifications

class Notifications {
	
	public static var granted = false
	
	public static var center: UNUserNotificationCenter {
		return UNUserNotificationCenter.current()
	}
	
	public static func create(_ body: String, title: String = "New Updates", badge: Int? = nil) {
		if granted {
			let content = UNMutableNotificationContent()
			content.title = title
			content.body = body
			content.sound = UNNotificationSound.default()
			
			let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
			
			let request = UNNotificationRequest(identifier: "updateNotification", content: content, trigger: trigger)
			
			center.removeAllPendingNotificationRequests()
			center.add(request) { error in
				if error != nil {
					print("Could not create notification. Reason: \(error?.localizedDescription)")
				}
			}
		}
	}
}
