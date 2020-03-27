//
//  AppDelegate.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 05/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	// MARK: Application Life Cycle
	/// The window associated with the application
	var window: UIWindow?
	
	/// Application has just launched from an inactive state
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		// MARK: RESET
//		if !UserDefaults.data.bool(forKey: "1.0 (1)") {
//			Settings().reset {
//				print("Successfully reset user preferences.")
//			}
//
//			UserDefaults.data.set(true, forKey: "1.0 (1)")
//		}
		
		UNUserNotificationCenter.current().delegate = self
		
		// Check user location and ask for permission if required
		UserLocation.current.startLocationManager()
		
		// Begin network monitoring
		_ = Networking.connection
		
		// Parse Stations
		_ = Stations.current
		
		// Parse POIs
		_ = Locations.shared
		
		// Begin checking for notifications
		_ = NotificationManager.session
		
		// Fetch Line Status
//		Status.current.updateStatus { (_) in }
		
		// Fetch Oyster Account
		Oyster.account.retrieveCards { (_, _) in }
		
		// Load Favourite Locations and Recent Journeys
		Journeys.shared.loadRecentJourneys()
		Journeys.shared.loadFavouriteLocations()
		
		return true
	}
	
}

extension AppDelegate: UNUserNotificationCenterDelegate {
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		print("Received notification whilst in foreground: \(notification.request.content.title) - \(notification.request.content.body)")
		
		completionHandler(.alert)
	}
	
}
