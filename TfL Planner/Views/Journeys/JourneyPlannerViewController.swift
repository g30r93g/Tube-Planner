//
//  JourneyPlannerViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 15/11/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class JourneyPlannerViewController: UIViewController {

	// MARK: IBOutlets
	@IBOutlet weak private var navigationBarHeight: NSLayoutConstraint!
	@IBOutlet weak private var fromStationField: DetailTextField!
	@IBOutlet weak private var toStationField: DetailTextField!
	@IBOutlet weak private var resultsCollection: UICollectionView!
	
	// MARK: Properties
	private var matchingLocations: [Locations.LocationResult] = [] {
		didSet {
			// Sort Matching Locations by distance and show stations and POIs before addresses
			if let userLocation = UserLocation.current.updateLocation() {
				self.matchingLocations.sort(by: { Locations.shared.determineDistance(from: userLocation, to: $0.coordinates) < Locations.shared.determineDistance(from: userLocation, to: $1.coordinates) && ($0.type == .station || $0.type == .poi) != ($1.type == .street) })
			}
			
			self.resultsCollection.reloadData()
		}
	}
	internal var routingFilters: Routing.Filters! = .standard
	private var selectedFrom: Locations.LocationResult?
	private var selectedTo: Locations.LocationResult?
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.addTextFieldEvents()
		self.setupView()
		self.showNearbyStations()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		self.removeTextFieldEvents()
	}
	
	// MARK: Methods
	/// Adds an event listener for when text is edited
	private func addTextFieldEvents() {
		self.fromStationField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
		self.toStationField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
	}
	
	/// Removes event listeners for when text is edited
	private func removeTextFieldEvents() {
		self.fromStationField.removeTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
		self.toStationField.removeTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
	}
	
	/// Sets up the view
	private func setupView() {
		// Hide toStationField
		self.navigationBarHeight.constant = 97
		self.toStationField.alpha = 0
		self.toStationField.isEnabled = false
		self.view.layoutIfNeeded()
		
		// Set editing mode for fromStationField to true
		self.fromStationField.becomeFirstResponder()
	}
	
	/// Shows nearby stations
	private func showNearbyStations() {
		if UserLocation.current.isPermitted {
			// Set matching stations to the 10 nearest stations
			self.matchingLocations = UserLocation.current.getNearestStationsToUser().map({Locations.StationResult(station: $0.station)})
			
			// Add user location as option
			if let userLocation = Locations.shared.userLocation {
				self.matchingLocations.insert(userLocation, at: 0)
			}
		}
	}
	
	/**
	Changes the state of the toStationField
	
	- Parameter to: Indicates whether the toStationField should be viewable or not
	*/
	private func changeToField(to state: Bool) {
		UIView.animate(withDuration: 0.4) {
			self.navigationBarHeight.constant = state ? 144 : 97
			self.view.layoutIfNeeded()
			
			self.toStationField.alpha = state ? 1 : 0
			self.toStationField.isEnabled = state
		}
	}
	
	/// Changes whether the matching stations (results) collection is visible
	/// - Parameter state: Indicates whether the results collection view should be viewable or not
	private func changeMatchingStations(to state: Bool) {
		UIView.animate(withDuration: state ? 0.1 : 0.4) {
			self.resultsCollection.alpha = state ? 0 : 1
		}
	}
	
	// MARK: Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Perform Routing" {
			guard let destVC = segue.destination as? ChooseJourneyViewController else { return }
			
			// Stop editing
			self.fromStationField.resignFirstResponder()
			self.toStationField.resignFirstResponder()
			
			// Get stations
			guard let from = self.selectedFrom else { return }
			guard let to = self.selectedTo else { return }
			
			// Set routing
			destVC.routing = Routing(from: from, to: to, filters: self.routingFilters)
			
		} else if segue.identifier == "Show Filters" {
			guard let destVC = segue.destination as? JourneyPlannerFilterViewController else { return }
			
			destVC.isNow = self.routingFilters.timePlanning == .none
			destVC.isAvoidingZoneOne = self.routingFilters.isAvoidingZoneOne
			destVC.maxChangesValue = self.routingFilters.maxChanges
			destVC.timePlanning = self.routingFilters.timePlanning
			
			destVC.completionHandler = { (filter) in
				self.routingFilters = filter
			}
		}
	}
	
	// MARK: IBActions
	/// User wishes to dismiss the view controller and return to `JourneyViewController`
	@IBAction private func dismissTapped(_ sender: UIButton) {
		self.removeTextFieldEvents()
		self.fromStationField.resignFirstResponder()
		self.toStationField.resignFirstResponder()
	}
	
	@IBAction private func showFiltersTapped(_ sender: UIButton) {
		self.performSegue(withIdentifier: "Show Filters", sender: self)
	}
	
}

// MARK: Text Field Delegates
extension JourneyPlannerViewController: UITextFieldDelegate {

	func textFieldDidBeginEditing(_ textField: UITextField) {
		if textField == self.fromStationField && (self.selectedFrom == nil && self.selectedTo == nil) {
			self.changeToField(to: false)
		}
	}
	
	/// Text field's content changed
	/// - parameter textField: The text field that was registered with this event
	@objc private func textFieldDidEdit(textField: UITextField) {
		// Remove all matching stations
		self.matchingLocations.removeAll()
		
		// Determine the search value
		// Must be capitalised to match data set
		// Also remove any spaces or newlines to avoid data set exploitation
		guard let searchValue = textField.text?.capitalized.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
		
		// Get all POIs that match the search value
		self.matchingLocations += Locations.shared.findPOIs(matching: searchValue).map({Locations.POIResult(pointOfInterest: $0)})
		
		// Get all stations that match the search value
		self.matchingLocations += Stations.current.search(searchValue).map({Locations.StationResult(station: $0)})
		
		// Fetch matching street locations
		Locations.shared.findMapLocations(matching: searchValue) { (results) in
			self.matchingLocations += results
			
			// If there's no matching locations hide the collection view and show a message
			self.changeMatchingStations(to: self.matchingLocations.isEmpty && !searchValue.isEmpty)
		}
		
		if textField == self.toStationField {
			// Remove the from location if the user is editing the to station field
			guard let fromLocation = self.selectedFrom else { return }
			
			self.matchingLocations.removeAll(where: {$0 == fromLocation})
		} else {
			// Add user location as option
			if let userLocationResult = Locations.shared.userLocation {
				self.matchingLocations.insert(userLocationResult, at: 0)
			}
		}
		
		// Show nearby stations if the fromStationField is editing and empty
		if searchValue.isEmpty && textField == self.fromStationField { self.showNearbyStations() }
		
		// If there's no matching locations hide the collection view and show a message
		self.changeMatchingStations(to: self.matchingLocations.isEmpty && !searchValue.isEmpty)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == self.fromStationField {
			// Check if the from station is set
			guard self.selectedFrom != nil else { return false }
			
			// Switch text field to toStationField
			self.toStationField.becomeFirstResponder()
			self.changeToField(to: true)
			
			// Setup for toStationField editing
			self.matchingLocations.removeAll()
		} else if textField == self.toStationField {
			// Check if both the from and to station is set
			guard self.selectedFrom != nil else { return false }
			guard self.selectedTo != nil else { return false }
			
			// End editing in both text fields
			self.toStationField.resignFirstResponder()
			
			// Perform segue to new view controller
			self.performSegue(withIdentifier: "Perform Routing", sender: self)
		}
		
		return true
	}
	
}

extension JourneyPlannerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.matchingLocations.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let data = self.matchingLocations[indexPath.item]
		
		switch data.type {
		case .station:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Matching Station", for: indexPath) as! MatchingStationCell
			
			if let station = (data as? Locations.StationResult)?.station {
				cell.setupCell(from: station)
			}
			
			return cell
		case .poi, .street:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Matching Location", for: indexPath) as! MatchingLocationCell
			
			if let poi = (data as? Locations.POIResult) {
				cell.setupCell(from: poi)
			} else if let streetAddress = (data as? Locations.StreetResult) {
				cell.setupCell(from: streetAddress)
			}
			
			return cell
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let data = self.matchingLocations[indexPath.item]
		
		if fromStationField.isEditing {
			self.selectedFrom = data
			self.fromStationField.text = data.displayName
			
			// FIXME: Why do i have to call this twice for the desired effect????????
			_ = textFieldShouldReturn(self.fromStationField)
			_ = textFieldShouldReturn(self.fromStationField)
		} else if toStationField.isEditing {
			self.selectedTo = data
			self.toStationField.text = data.displayName
			_ = textFieldShouldReturn(self.toStationField)
		}
		
		print("From Location: \(self.selectedFrom?.displayName ?? "<UNSELECTED>")  ----  To Location: \(self.selectedTo?.displayName ?? "<UNSELECTED>")")
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		switch self.matchingLocations[indexPath.item].type {
		case .station:
			return CGSize(width: UIScreen.main.bounds.width - 40, height: 128)
		case .poi, .street:
			return CGSize(width: UIScreen.main.bounds.width - 40, height: 75)
		}
	}
	
}
