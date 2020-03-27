//
//  JourneyViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 16/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class JourneyViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var newJourney: RoundButton!
	@IBOutlet weak private var addFavouriteLocation: RoundButton!
	@IBOutlet weak private var currentJourneyContainer: UIView!
	@IBOutlet weak private var currentJourneyHeight: NSLayoutConstraint!
	@IBOutlet weak private var currentJourneyContinueButton: UIButton!
	@IBOutlet weak private var currentJourneyFrom: UILabel!
	@IBOutlet weak private var currentJourneyTo: UILabel!
	@IBOutlet weak private var favouriteLocationsCollection: UICollectionView!
	@IBOutlet weak private var recentJourneysCollection: UICollectionView!
	
	// MARK: Variables
	public var currentJourney: Routing?
	
	// MARK: View Controller Life Cycle
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.setupView()
		self.setupFavoriteLocationsView()
		self.setupCurrentJourney()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
	// MARK: Methods
	/// Setup view
	private func setupView() {
		NotificationCenter.default.addObserver(self, selector: #selector(favouriteLocationsDidChange(_:)), name: Notification.Name(rawValue: "favouriteLocationsDidChange"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(recentJourneysDidChange(_:)), name: Notification.Name(rawValue: "recentJourneysDidChange"), object: nil)
	}
	
	/// Setup the favourite locations view
	private func setupFavoriteLocationsView() {
		let showFavouriteLocations = Journeys.shared.favouriteLocations.isEmpty

		self.favouriteLocationsCollection.alpha = showFavouriteLocations ? 0 : 1
		self.addFavouriteLocation.alpha = showFavouriteLocations ? 1 : 0
		self.addFavouriteLocation.isUserInteractionEnabled = showFavouriteLocations
		
		self.favouriteLocationsCollection.reloadData()
	}
	
	/// Updates the view when favourite locations are updated
	@objc private func favouriteLocationsDidChange(_ notification: Notification) {
		DispatchQueue.main.async {
			self.favouriteLocationsCollection.reloadData()
			self.setupFavoriteLocationsView()
		}
		
	}
	
	/// Updates the view when recent journeys are updated
	@objc private func recentJourneysDidChange(_ notification: Notification) {
		DispatchQueue.main.async {
			self.recentJourneysCollection.reloadData()
			
			UIView.animate(withDuration: 0.2) {
				self.recentJourneysCollection.alpha = Journeys.shared.journeys.isEmpty ? 0 : 1
			}
		}
	}
	
	/// Shows current journey "section"
	/// Determines if current journey is in progress
	private func setupCurrentJourney() {
		// Determine if is on journey
		let isOnJourney = self.currentJourney != nil
		
		// Set height to 150 if is on journey, otherwise hide
		self.currentJourneyHeight.constant = isOnJourney ? 150 : 0
		
		// Set alpha of all container components to 1
		self.currentJourneyContainer.alpha = isOnJourney ? 1 : 0
		self.currentJourneyContinueButton.isUserInteractionEnabled = isOnJourney
		
		if let currentJourney = self.currentJourney {
			self.currentJourneyFrom.text = currentJourney.from.displayName
			self.currentJourneyTo.text = currentJourney.to.displayName
		}
	}
	
	// MARK: Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Route Selected" {
			// Cancel Current Journey
			guard let destVC = segue.destination as? ChooseJourneyViewController else { return }
			guard let selectedIndex = self.recentJourneysCollection.indexPathsForSelectedItems?.first?.item else { return }
			let data = Journeys.shared.journeys[selectedIndex]
			
			destVC.routing = Routing(from: data.from, to: data.to, filters: .standard)
		} else if segue.identifier == "Favourite Location Selected" {
			guard let destVC = segue.destination as? ChooseJourneyViewController else { return }
			guard let selectedIndex = self.favouriteLocationsCollection.indexPathsForSelectedItems?.first?.item else { return }
			let data = Journeys.shared.favouriteLocations[selectedIndex]
			
			if let userLocation = Locations.shared.userLocation {
				destVC.routing = Routing(from: userLocation, to: data.location, filters: .standard)
			}
		} else if segue.identifier == "Continue with Current Journey" {
			// Return to current journey
			guard let destVC = segue.destination as? RouteViewController else { return }
			
			if let currentJourney = self.currentJourney {
				destVC.routing = currentJourney
				destVC.changeRouteTimedOut = true
			}
		}
	}
	
	// MARK: IBActions
	/// Unwind segue for when coming back to this view
	@IBAction private func unwindToJourneys(_ segue: UIStoryboardSegue) {
		self.recentJourneysCollection.reloadData()
		self.favouriteLocationsCollection.reloadData()
		self.setupCurrentJourney()
    }
	
	@IBAction private func startNewJourney(_ sender: UIButton) {
		self.performSegue(withIdentifier: "New Journey", sender: self)
	}
	
	@IBAction private func addNewFavouriteLocation(_ sender: UIButton) {
		self.performSegue(withIdentifier: "Add Favourite Location", sender: self)
	}
	
	@IBAction private func continueWithCurrentJourney(_ sender: UIButton) {
		self.performSegue(withIdentifier: "Continue with Current Journey", sender: self)
	}
	
}

extension JourneyViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if collectionView == favouriteLocationsCollection {
			// Return one more than the actual value to add a cell allowing user to add another favourite location
			return Journeys.shared.favouriteLocations.count + 1
		} else if collectionView == recentJourneysCollection {
			return Journeys.shared.journeys.count
		} else {
			return 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if collectionView == favouriteLocationsCollection {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Favourite Location", for: indexPath) as! FavouriteLocationCell
			
			// Check if cell should be for adding a new location
			if indexPath.item == Journeys.shared.favouriteLocations.count {
				cell.setupForAddingLocation()
			} else {
				let data = Journeys.shared.favouriteLocations[indexPath.item]
				
				cell.setupCell(from: data)
			}
			
			return cell
		} else if collectionView == recentJourneysCollection {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Recent Journey", for: indexPath) as! RecentJourneyCell
			let data = Journeys.shared.journeys[indexPath.item]
			
			cell.setupCell(from: data)
			
			return cell
		} else {
			return UICollectionViewCell()
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		if collectionView == self.favouriteLocationsCollection {
			// Favourite Locations
			return CGSize(width: (UIScreen.main.bounds.width / 2) - 60, height: 75)
		} else {
			// Recent Journeys
			return CGSize(width: (UIScreen.main.bounds.width - 40), height: 94)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if collectionView == favouriteLocationsCollection {
			if indexPath.item == Journeys.shared.favouriteLocations.count {
				self.performSegue(withIdentifier: "Add Favourite Location", sender: self)
			} else {
				self.performSegue(withIdentifier: "Favourite Location Selected", sender: self)
			}
		} else if collectionView == recentJourneysCollection {
			self.performSegue(withIdentifier: "Route Selected", sender: self)
		}
	}
	
}
