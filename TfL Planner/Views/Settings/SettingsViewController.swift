//
//  SettingsViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 30/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var dataSavingToggle: UISwitch!
	@IBOutlet weak private var findFareEstimateToggle: UISwitch!
	@IBOutlet weak private var lineStatusInPlannerToggle: UISwitch!
	@IBOutlet weak private var hideRoutesWithPoorStatusToggle: UISwitch!
	@IBOutlet weak private var suggestFavouriteLocationsToggle: UISwitch!
	@IBOutlet weak private var oysterBalanceInRoutingToggle: UISwitch!
	@IBOutlet weak private var numberOfStartStations: UILabel!
	@IBOutlet weak private var travelcardUsed: UILabel!
	@IBOutlet weak private var suggestionType: UILabel!
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
        super.viewDidLoad()
		// Do any additional setup after loading the view.
		
		self.setupView()
    }
	
	// MARK: Methods
	/// Sets up the view
	private func setupView() {
		self.dataSavingToggle.isOn = Settings().isSavingData
		self.lineStatusInPlannerToggle.isOn = Settings().isShowingStatusInJourneys
		self.hideRoutesWithPoorStatusToggle.isOn = Settings().hidingRoutesWithPoorStatus
		self.findFareEstimateToggle.isOn = Settings().isFindingFareEstimates
		self.suggestFavouriteLocationsToggle.isOn = Settings().suggestFavouriteLocations
		self.oysterBalanceInRoutingToggle.isOn = Settings().isShowingOysterInJourneys
		
		if !self.findFareEstimateToggle.isOn { self.oysterBalanceInRoutingToggle.isOn = false; self.oysterBalanceInRoutingToggle.isEnabled = false }
		
		self.updateTravelcard()
		self.updateSuggestionType()
		self.updateNumberOfStartStations()
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateNumberOfStartStations), name: Notification.Name(rawValue: "routeStartStationsDidChange"), object: nil)
	}
	
	/// Updates the ```numberOfStartStations``` label
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
	
	/// Updates the `travelcardUsed` label
	private func updateTravelcard() {
		switch Settings().travelcard {
		case .payg:
			self.travelcardUsed.text = "Oyster / Contactless"
		case .apprentice:
			self.travelcardUsed.text = "Apprentice"
		case .railcard:
			self.travelcardUsed.text = "Railcard"
		case .jobcentrePlus:
			self.travelcardUsed.text = "Jobcentre Plus"
		case .student18plus:
			self.travelcardUsed.text = "Student 18+"
		case .student16plus:
			self.travelcardUsed.text = "Student 16+"
		case .child11to15:
			self.travelcardUsed.text = "11-15"
		case .child5to10:
			self.travelcardUsed.text = "5-10"
		}
	}
	
	/// Updates the `suggestionType` label
	private func updateSuggestionType() {
		switch Settings().preferredRoutingSuggestion {
		case .fastest:
			self.suggestionType.text = "Fastest"
		case .fewestChanges:
			self.suggestionType.text = "Fewest Changes"
		case .lowestFare:
			self.suggestionType.text = "Lowest Fare"
		case .leastWalking:
			self.suggestionType.text = "Least Walking"
		}
	}
	
	// MARK: Table View Methods
	override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let headerView = view as! UITableViewHeaderFooterView
		
		headerView.tintColor = UIColor(named: "Text Field Background") ?? .white
		headerView.textLabel?.textColor = .white
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		switch indexPath.section {
		case 0:
			switch indexPath.row {
			case 1:
				// Privacy Policy
				print("Showing Privacy Policy")
				let alert = UIAlertController(title: "Privacy Policy\n\n\n\n\n\n\n\n\n\n\n\n", message: "", preferredStyle: .alert)
				
				// Add Privacy Policy as a scrollable text label
				let text = UITextView(frame: CGRect(x: 8.0, y: 50.0, width: 260, height: 250.0))
				
				text.allowsEditingTextAttributes = false
				text.isEditable = false
				text.isSelectable = false
				text.clipsToBounds = true
				text.showsVerticalScrollIndicator = false
				text.showsHorizontalScrollIndicator = false
				text.backgroundColor = UIColor.white.withAlphaComponent(0)
				text.text = Settings().privacyPolicy
				text.font = UIFont(name: "Johnston100-Light", size: 12)
				
				alert.view.addSubview(text)
				alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
				
				present(alert, animated: true, completion: nil)
			case 2:
				// Reset application
				let alert = UIAlertController(title: "Reset App", message: "Are you sure you wish to reset the app?", preferredStyle: .alert)
				
				alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
					Settings().reset {
						self.performSegue(withIdentifier: "Re-perform Onboarding", sender: self)
					}
				}))
				
				alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (_) in
					alert.dismiss(animated: true, completion: nil)
				}))
				
				self.present(alert, animated: true, completion:	nil)
			default:
				break
			}
		case 1:
			switch indexPath.row {
			case 0:
				// Select Suggestion Stations
				self.performSegue(withIdentifier: "Start Route Suggestions", sender: self)
			case 1:
				// Select Travelcard
				let alert = UIAlertController(title: "Select Travelcard", message: "", preferredStyle: .actionSheet)
				
				// Show Travelcard Options
				alert.addAction(UIAlertAction(title: "Oyster / Contactless", style: .default, handler: { (_) in
					Settings().setTravelcard(to: .payg)
					self.updateTravelcard()
				}))
				alert.addAction(UIAlertAction(title: "Railcards", style: .default, handler: { (_) in
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
				
				// Cancel Button
				alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
				
				present(alert, animated: true, completion: nil)
			case 3:
				// Select Preferred Routing Type
				let alert = UIAlertController(title: "Select Preferred Routing Type", message: "", preferredStyle: .actionSheet)
				
				// Show Travelcard Options
				alert.addAction(UIAlertAction(title: "Fastest", style: .default, handler: { (_) in
					Settings().changePreferredRoutingSuggestion(to: .fastest)
					self.updateSuggestionType()
				}))
				alert.addAction(UIAlertAction(title: "Fewest Changes", style: .default, handler: { (_) in
					Settings().changePreferredRoutingSuggestion(to: .fewestChanges)
					self.updateSuggestionType()
				}))
				alert.addAction(UIAlertAction(title: "Lowest Fare", style: .default, handler: { (_) in
					Settings().changePreferredRoutingSuggestion(to: .lowestFare)
					self.updateSuggestionType()
				}))
				alert.addAction(UIAlertAction(title: "Least Walking", style: .default, handler: { (_) in
					Settings().changePreferredRoutingSuggestion(to: .leastWalking)
					self.updateSuggestionType()
				}))
				
				// Add checkmark
				switch Settings().preferredRoutingSuggestion {
				case .fastest:
					alert.actions[0].setValue(true, forKey: "checked")
				case .fewestChanges:
					alert.actions[1].setValue(true, forKey: "checked")
				case .lowestFare:
					alert.actions[2].setValue(true, forKey: "checked")
				case .leastWalking:
					alert.actions[3].setValue(true, forKey: "checked")
				}
				
				// Cancel Button
				alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
				
				present(alert, animated: true, completion: nil)
			case 5:
				// Manage Favourite Locations
				self.performSegue(withIdentifier: "Edit Favourite Locations", sender: self)
			case 6:
				// Clear Recent Journeys
				let alert = UIAlertController(title: "Clear Recent Journeys", message: "This will remove all recent journeys from this device.", preferredStyle: .alert)
				
				alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
				alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
					Journeys.shared.clearRecentJourneys()
				}))
				
				present(alert, animated: true, completion: nil)
			default:
				break
			}
		case 2:
			break
		case 3:
			switch indexPath.row {
			case 1:
				// Update Oyster Account
				self.performSegue(withIdentifier: "UpdateOysterLogin", sender: self)
			case 2:
				// Revoke Oyster Account Access
				let alert = UIAlertController(title: "Revoke Oyster Account?", message: "This will remove your oyster account's email and password from this device.", preferredStyle: .alert)
				
				alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
				alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
					// Remove account details here
					Settings().removeOysterAccount()
				}))
				
				self.present(alert, animated: true, completion: nil)
			default:
				break
			}
		default:
			break
		}
	}
	
	/// Presents an alert to the user
	/// - parameter title: The message of the alert
	private func showAlert(with title: String) {
		let alert = UIAlertController(title: title, message: "", preferredStyle: .actionSheet)
		
		alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
		
		self.present(alert, animated: true, completion: nil)
	}
	
	// MARK: Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "UpdateOysterLogin" {
			guard let destVC = segue.destination as? AddOysterAccountViewController else { return }
			
			destVC.isUpdatingDetails = true
		}
	}
	
	// MARK: IBAction
	@IBAction private func dataSavingToggled(_ sender: UISwitch) {
		Settings().changeDataSaving(to: sender.isOn)
	}
	
	@IBAction private func lineStatusInPlannerToggled(_ sender: UISwitch) {
		Settings().changeStatusInJourneys(to: sender.isOn)
		
		if !sender.isOn {
			Settings().updateHideRoutesWithPoorStatus(to: false)
			self.hideRoutesWithPoorStatusToggle.setOn(false, animated: true)
			self.hideRoutesWithPoorStatusToggle.isEnabled = false
		}
	}
	
	@IBAction private func userChangedFareEstimateRetrieval(_ sender: UISwitch) {
		Settings().changeFareEstimateRetrieval(to: sender.isOn)
		
		if !sender.isOn {
			self.oysterBalanceInRoutingToggle.isEnabled = false
			self.oysterBalanceInRoutingToggle.setOn(false, animated: true)
		}
	}
	
	@IBAction private func oysterInPlannerToggled(_ sender: UISwitch) {
		Settings().changeOysterInJourneys(to: sender.isOn)
	}
	
	@IBAction private func suggestFavouriteLocationsToggled(_ sender: UISwitch) {
		Settings().updateSuggestingFavouriteLocations(to: sender.isOn)
	}
	
	@IBAction private func hideRoutesWithPoorStatusToggled(_ sender: UISwitch) {
		Settings().updateHideRoutesWithPoorStatus(to: sender.isOn)
		
		if sender.isOn {
			Settings().changeStatusInJourneys(to: true)
			self.lineStatusInPlannerToggle.setOn(sender.isOn, animated: true)
		}
	}
	
	@IBAction private func unwindToSettings(_ sender: UIStoryboardSegue) { }
	
}
