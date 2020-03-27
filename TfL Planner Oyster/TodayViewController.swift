//
//  TodayViewController.swift
//  TfL Planner Today
//
//  Created by George Nick Gorzynski on 12/11/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import NotificationCenter
import UIKit

class TodayViewController: UIViewController, NCWidgetProviding {
	
	// MARK: IBOutlets
	@IBOutlet weak private var cardNumber: UILabel!
	@IBOutlet weak private var cardBalance: UILabel!
	
	@IBOutlet weak private var lastJourneyDate: UILabel!
	@IBOutlet weak private var lastJourneyFare: UILabel!
	@IBOutlet weak private var lastJourneyFrom: UILabel!
	@IBOutlet weak private var lastJourneyTo: UILabel!
	
	// MARK: Properties
	/// The card to display
	private var cardToDisplay: String?
	
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		
		_ = Networking.connection
		
		self.cardToDisplay = UserDefaults.data.string(forKey: "oyster-favourite-number")
		self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
    }
	
	// MARK: Methods
	// Setup the view
	private func setupView(completion: @escaping(NCUpdateResult) -> Void) {
		if self.cardToDisplay == nil || self.cardToDisplay?.isEmpty ?? false {
			self.cardNumber.text = "No Favourite Card Set"
			self.cardBalance.text = "Please go to settings to change this."
			
			completion(.failed)
			return
		}
		
		print("View Setting Up...")
		Oyster.account.retrieveCards { (oysterCards, contactlessCards) in
			if !oysterCards.isEmpty && !contactlessCards.isEmpty {
				// Display oyster card data
				guard let cardNumber = self.cardToDisplay else { completion(.failed); return }
					
				if cardNumber.count == 12 {
					// Oyster card
					guard let oysterCard = oysterCards.first(where: {$0.number == cardNumber}) else { completion(.noData); print("[Widget] No data"); return }
					
					self.cardNumber.text = "Card Number: \(oysterCard.number)"
					self.cardBalance.text = "Balance: £\(String(format: "%.2f", oysterCard.balance))"
					
					// Display most recent journey
					guard let recentJourney = oysterCard.journeyHistory.first(where: {$0.transactionType != .topUp}) else { completion(.newData); print("[Widget] No Journey History"); return }
					self.lastJourneyDate.text = "Date: \(recentJourney.startTime.friendlyFormat())"
					
					if recentJourney.transactionType == .bus {
						self.setupBusJourney(busRoute: recentJourney.busRoute!, fare: recentJourney.fare)
					} else {
						self.setupTubeJourney(from: recentJourney.from, to: recentJourney.to, fare: recentJourney.fare)
					}
					
					self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
					completion(.newData)
				} else {
					// Contactless Card
					guard let contactlessCard = contactlessCards.first(where: {$0.identifier == cardNumber}) else { completion(.noData); print("[Widget] No data"); return }
					
					self.cardNumber.text = "Card Ending: \(contactlessCard.lastFourDigits)"
					self.cardBalance.text = "Vendor: \(contactlessCard.cardType.rawValue)"
					
					guard let recentJourney = contactlessCard.journeyHistory.first(where: {$0.transactionType != .unknown}) else { completion(.newData); print("[Widget] No Journey History"); return }
					self.lastJourneyDate.text = "Date: \(recentJourney.startTime.friendlyFormat())"
					
					if recentJourney.transactionType == .bus {
						guard let busRoute = recentJourney.busRoute else { return }
						self.setupBusJourney(busRoute: busRoute, fare: recentJourney.finalFare)
					} else {
						self.setupTubeJourney(from: recentJourney.from, to: recentJourney.to, fare: recentJourney.finalFare)
					}
					
					self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
					completion(.newData)
				}
			} else {
				self.errorText()
				print("Unable to retrieve cards")
				completion(.noData)
			}
		}
	}
	
	private func cardIsSetUp() -> Bool {
		return Settings().oysterUsername == "" || Settings().oysterPassword == ""
	}
	
	/// Setup the widget for a bus journey
	private func setupBusJourney(busRoute: String, fare: Double) {
		self.lastJourneyFrom.text = "Bus Route: \(busRoute)"
		self.lastJourneyTo.text = "Fare: £" + String(format: "%.2f", fare)
		self.lastJourneyFare.text = ""
	}
	
	/// Setup the widget for a tube journey
	private func setupTubeJourney(from: String, to: String?, fare: Double) {
		self.lastJourneyFare.text = "Fare: £" + String(format: "%.2f", fare)
		
		self.lastJourneyFrom.text = "From: \(from)"
		if let to = to {
			self.lastJourneyTo.text = "To: \(to)"
		} else {
			self.lastJourneyTo.text = ""
		}
	}
	
	/// Show an error
	private func errorText() {
		var cardNumber: String {
			if let card = self.cardToDisplay {
				return card
			} else {
				return "oyster card."
			}
		}
		
		self.cardNumber.text = "Could not get \(cardNumber)"
		self.cardBalance.text = "Balance: Not available"
		self.lastJourneyDate.text = "Date: Not available"
		self.lastJourneyFare.text = "Fare: Not available"
		self.lastJourneyFrom.text = "From: Not available"
		self.lastJourneyTo.text = "To: Not available"
		
		self.extensionContext?.widgetLargestAvailableDisplayMode = .compact
	}
	
	// MARK: NCWidgetProviding
	func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
		print("[Widget] Update requested")
		
		self.setupView { (updateResult) in
			completionHandler(updateResult)
		}
	}
	
	func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 100)
        } else if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 260)
        }
    }
	
}
