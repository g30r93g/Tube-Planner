//
//  CustomiseSettingsViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 16/09/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class CustomiseSettingsViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var containerScroll: UIScrollView!
	@IBOutlet weak private var dataSavingToggle: UISwitch!
	@IBOutlet weak private var fareEstimateToggle: UISwitch!
	@IBOutlet weak private var lineStatusInPlannerToggle: UISwitch!
	@IBOutlet weak private var numberOfStartStations: UILabel!
	@IBOutlet weak private var routeSortingLabel: UILabel!
	@IBOutlet weak private var routeSortingButton: UIButton!
	@IBOutlet weak private var travelcardLabel: UILabel!
	@IBOutlet weak private var travelcardButton: RoundButton!
	@IBOutlet weak private var continueButton: RoundButton!
	
	// MARK: Variables
	/// Determines whether a travelcard has been selected.
	private var travelcardSelected: Bool = false {
		didSet {
			self.enableContinue()
		}
	}
	
	private var routeSorting: Routing.Heuristic = Settings().preferredRoutingSuggestion
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateNumberOfStartStations), name: Notification.Name(rawValue: "routeStartStationsDidChange"), object: nil)
		self.continueButton.alpha = 0.5
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.updateNumberOfStartStations()
	}
	
	// MARK: Methods
	/// Save user preferences
	private func saveUserPrefs() {
		Settings().changeDataSaving(to: self.dataSavingToggle.isOn)
		Settings().changeFareEstimateRetrieval(to: self.fareEstimateToggle.isOn)
		Settings().changeStatusInJourneys(to: self.lineStatusInPlannerToggle.isOn)
	}
	
	/// Display route sorting filters
	private func showRouteSortingPicker() {
		let alert = UIAlertController(title: "Route Sorting", message: nil, preferredStyle: .actionSheet)
		
		alert.addAction(UIAlertAction(title: "Fastest", style: .default, handler: { (_) in
			Settings().changePreferredRoutingSuggestion(to: .fastest)
			self.updateRouteSorting()
		}))
		alert.addAction(UIAlertAction(title: "Fewest Changes", style: .default, handler: { (_) in
			Settings().changePreferredRoutingSuggestion(to: .fewestChanges)
			self.updateRouteSorting()
		}))
		alert.addAction(UIAlertAction(title: "Least Walking", style: .default, handler: { (_) in
			Settings().changePreferredRoutingSuggestion(to: .leastWalking)
			self.updateRouteSorting()
		}))
		alert.addAction(UIAlertAction(title: "Lowest Fare", style: .default, handler: { (_) in
			Settings().changePreferredRoutingSuggestion(to: .lowestFare)
			self.updateRouteSorting()
		}))
		
		switch Settings().preferredRoutingSuggestion {
		case .fastest:
			alert.actions[0].setValue(true, forKey: "checked")
		case .fewestChanges:
			alert.actions[1].setValue(true, forKey: "checked")
		case .leastWalking:
			alert.actions[2].setValue(true, forKey: "checked")
		case .lowestFare:
			alert.actions[3].setValue(true, forKey: "checked")
		}
		
		// Cancel Button
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		
		// Place presentation controller in correct place
		if UIDevice.current.userInterfaceIdiom == .pad {
			if let popoverController = alert.popoverPresentationController {
				popoverController.sourceView = self.view
				popoverController.sourceRect = CGRect(x: self.travelcardButton.frame.midX, y: self.travelcardButton.frame.midY * 1.58, width: 0, height: 0)
			}
		}
		
		// Present Alert
		present(alert, animated: true, completion: nil)
	}
	
	/// Display a travelcard picker to the user.
	private func showTravelcardPicker() {
		let alert = UIAlertController(title: "Select Travelcard", message: nil, preferredStyle: .actionSheet)
		
		// Show Travelcard Options
		alert.addAction(UIAlertAction(title: "Oyster / Contactless", style: .default, handler: { (_) in
			Settings().setTravelcard(to: .payg)
			self.updateTravelcard()
		}))
		alert.addAction(UIAlertAction(title: "Railcard", style: .default, handler: { (_) in
			Settings().setTravelcard(to: .railcard)
			self.updateTravelcard()
		}))
		alert.addAction(UIAlertAction(title: "Jobcentre Plus", style: .default, handler: { (_) in
			Settings().setTravelcard(to: .jobcentrePlus)
			self.updateTravelcard()
		}))
		alert.addAction(UIAlertAction(title: "Apprentice", style: .default, handler: { (_) in
			Settings().setTravelcard(to: .apprentice)
			self.updateTravelcard()
		}))
		alert.addAction(UIAlertAction(title: "Student 18+", style: .default, handler: { (_) in
			Settings().setTravelcard(to: .student18plus)
			self.updateTravelcard()
		}))
		alert.addAction(UIAlertAction(title: "Student 16+", style: .default, handler: { (_) in
			Settings().setTravelcard(to: .student16plus)
			self.updateTravelcard()
		}))
		alert.addAction(UIAlertAction(title: "11-15", style: .default, handler: { (_) in
			Settings().setTravelcard(to: .child11to15)
			self.updateTravelcard()
		}))
		alert.addAction(UIAlertAction(title: "5-10", style: .default, handler: { (_) in
			Settings().setTravelcard(to: .child5to10)
			self.updateTravelcard()
		}))
		
		if self.travelcardSelected {
			switch Settings().travelcard {
			case .payg:
				alert.actions[0].setValue(true, forKey: "checked")
			case .apprentice:
				alert.actions[1].setValue(true, forKey: "checked")
			case .railcard:
				alert.actions[2].setValue(true, forKey: "checked")
			case .jobcentrePlus:
				alert.actions[3].setValue(true, forKey: "checked")
			case .student18plus:
				alert.actions[4].setValue(true, forKey: "checked")
			case .student16plus:
				alert.actions[5].setValue(true, forKey: "checked")
			case .child11to15:
				alert.actions[6].setValue(true, forKey: "checked")
			case .child5to10:
				alert.actions[7].setValue(true, forKey: "checked")
			}
		}
		
		// Cancel Button
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		
		// Place presentation controller in correct place
		if UIDevice.current.userInterfaceIdiom == .pad {
			if let popoverController = alert.popoverPresentationController {
				popoverController.sourceView = self.view
				popoverController.sourceRect = CGRect(x: self.travelcardButton.frame.midX, y: self.travelcardButton.frame.midY * 1.58, width: 0, height: 0)
			}
		}
		
		// Present Alert
		present(alert, animated: true, completion: nil)
	}
	
	/// Update the selection text for the user's preferred route sorting
	private func updateRouteSorting() {
		switch Settings().preferredRoutingSuggestion {
		case .fastest:
			self.routeSortingLabel.text = "Fastest"
		case .fewestChanges:
			self.routeSortingLabel.text = "Fewest Changes"
		case .leastWalking:
			self.routeSortingLabel.text = "Least Walking"
		case .lowestFare:
			self.routeSortingLabel.text = "Lowest Fare"
		}
	}
	
	/// Update the selection text for the user's travelcard.
	private func updateTravelcard() {
		self.travelcardSelected = true
		
		switch Settings().travelcard {
		case .payg:
			self.travelcardLabel.text = "Oyster / Contactless"
		case .apprentice:
			self.travelcardLabel.text = "Apprentice"
		case .railcard:
			self.travelcardLabel.text = "Railcard"
		case .jobcentrePlus:
			self.travelcardLabel.text = "Jobcentre Plus"
		case .student18plus:
			self.travelcardLabel.text = "Student 18+"
		case .student16plus:
			self.travelcardLabel.text = "Student 16+"
		case .child11to15:
			self.travelcardLabel.text = "11-15"
		case .child5to10:
			self.travelcardLabel.text = "5-10"
		}
	}
	
	@objc private func updateNumberOfStartStations() {
		let numberOfStations = Settings().routeStartStations.count
		
		if numberOfStations == 0 {
			self.numberOfStartStations.text = "Not alerting at any stations"
		} else if numberOfStations == 1 {
			self.numberOfStartStations.text = "Alerting at 1 station"
		} else if numberOfStations == Stations.current.stations.count {
			self.numberOfStartStations.text = "Alerting at all stations"
		} else {
			self.numberOfStartStations.text = "Alerting at \(numberOfStations) stations"
		}
	}
	
	/// Enables the continue button.
	/// Only performed when `travelcardSelected` is `true`
	private func enableContinue() {
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
			self.continueButton.alpha = (self.travelcardSelected ? 1 : 0.5)
			self.continueButton.isUserInteractionEnabled = self.travelcardSelected
		})
	}
	
	/// Presents a popup to the user that they need to select a travelcard.
	private func hintToContinue() {
		let alert = UIAlertController(title: "Please select a travelcard", message: nil, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .default))
		self.present(alert, animated: true, completion: nil)
	}
	
	// MARK: IBActions
	/// Hints to select a travelcard or segues to set favourite locations.
	@IBAction private func continueTapped(_ sender: UIButton) {
		self.saveUserPrefs()
		
		if self.travelcardSelected {
			self.performSegue(withIdentifier: "Set Favourite Locations", sender: nil)
		} else {
			self.hintToContinue()
		}
	}
	
	/// Handles user selecting `routeSortingButton`
	@IBAction private func selectRouteSorting(_ sender: UIButton) {
		self.showRouteSortingPicker()
	}
	
	/// Handles user selecting `travelcardButton`
	@IBAction private func selectTravelcardTapped(_ sender: UIButton) {
		self.showTravelcardPicker()
	}
	
}
