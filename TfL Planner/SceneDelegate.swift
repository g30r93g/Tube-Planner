//
//  SceneDelegate.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 05/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	
	/// The window associated with the application
	var window: UIWindow?
	
	/// Tells the delegate about the addition of a scene to the app.
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let windowScene = (scene as? UIWindowScene) else { return }
		self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
		self.window?.windowScene = windowScene
		
		// Determine if user has previously used application for onboarding
		self.determineStoryboard()
	}
	
	/// Tells the delegate that the scene became active and is now responding to user events.
	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
		
		_ = UserLocation.current.updateLocation()
		
		// Force Dark Mode for Application
		if #available(iOS 13.0, *) {
			self.window?.overrideUserInterfaceStyle = .dark
		}
	}
	
	// MARK: Methods
	/// Determines the correct `UIStoryboard` to present to the user
	func determineStoryboard() {
		if Settings().hasCompletedOnboarding {
			// Show Main.storyboard
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let initialVC = storyboard.instantiateInitialViewController()
			self.window?.rootViewController = initialVC
		} else {
			// Show Onboarding.storyboard
			let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
			let initialVC = storyboard.instantiateInitialViewController()
			self.window?.rootViewController = initialVC
		}
		
		self.window?.makeKeyAndVisible()
	}
	
}
