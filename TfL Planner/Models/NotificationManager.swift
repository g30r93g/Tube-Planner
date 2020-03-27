//
//  NotificationManager.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 27/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import CoreLocation
import UserNotifications

class NotificationManager {
	
	// MARK: Shared Instance
	static let session = NotificationManager()
	
	// MARK: Initialisers
	init() {
		self.askForNotificationPermissions()
	}
	
	// MARK: Properties
	var isPermitted: Bool = false
	
	// MARK: Start Route Methods
	public func addStationStartNotification(for stations: [Stations.Station]) {
		guard UserLocation.current.isPermitted && self.isPermitted else { return }
		
		for station in stations {
			let region = CLCircularRegion(center: station.coordinates(), radius: 50, identifier: station.name)
			region.notifyOnEntry = true
			region.notifyOnExit = false
			
			let content = self.createStationStartContent(for: station)
			let startJourneyAction = UNNotificationAction(identifier: "Start Journey", title: "Start Journey", options: .foreground)
			let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
			
			let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
			let category = UNNotificationCategory(identifier: "Start Journey", actions: [startJourneyAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
			
			self.addNotification(request)
			self.addCategory(category)
		}
	}
	
	private func createStationStartContent(for station: Stations.Station) -> UNNotificationContent {
		let notification = UNMutableNotificationContent()
		
		notification.title = "Start a Journey?"
		notification.body = "It looks like you're near \(station.name) station."
		notification.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "Resources/Alert Tones/alert_tone.caf"))
		notification.categoryIdentifier = "Start Journey"
		
		return notification
	}
	
}

extension NotificationManager {
	
	private func askForNotificationPermissions() {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (authorized, error) in
			if error != nil {
				self.isPermitted = false
			} else {
				self.isPermitted = authorized
			}
		}
	}
	
	private func addNotification(_ notification: UNNotificationRequest) {
		let center = UNUserNotificationCenter.current()
		
		center.removeAllPendingNotificationRequests()
		center.removeAllDeliveredNotifications()
		center.getPendingNotificationRequests { (pendingNotifications) in
			if !pendingNotifications.contains(where: {$0.content.title == notification.content.title && $0.content.body == notification.content.body}) {
				center.add(notification) { (error) in
					if let error = error {
						fatalError(error.localizedDescription)
					}
				}
			}
			
			pendingNotifications.forEach({print("[NotificationManager] Pending Notification: \($0.content.title) - \($0.content.body)")})
		}
	}
	
	private func addCategory(_ category: UNNotificationCategory) {
		let center = UNUserNotificationCenter.current()
		
		center.getNotificationCategories { (categories) in
			if !categories.contains(category) {
				var newCategories = categories
				newCategories.insert(category)
				
				center.setNotificationCategories(newCategories)
			}
		}
	}
	
	private func removeNotification(title: String = "", body: String = "") {
		let center = UNUserNotificationCenter.current()
		center.getPendingNotificationRequests { (pendingNotifications) in
			let notificationsToRemove = pendingNotifications.filter({$0.content.title == title && $0.content.body == body}).map({$0.identifier})
			center.removePendingNotificationRequests(withIdentifiers: notificationsToRemove)
		}
	}
	
}
