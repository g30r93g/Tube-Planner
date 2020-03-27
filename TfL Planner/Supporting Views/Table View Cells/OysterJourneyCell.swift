//
//  OysterJourneyCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 08/07/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class OysterJourneyCell: UITableViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var date: UILabel!
	@IBOutlet weak private var from: UILabel!
	@IBOutlet weak private var to: UILabel!
	@IBOutlet weak private var fare: UILabel!
	@IBOutlet weak private var fareType: RoundLabel!
	
	// MARK: Methods
	func setupCell(from data: Oyster.OysterJourney) {
		self.date.text = data.startTime.friendlyFormat()
		self.fareType.alpha = 0.0
		
		if data.transactionType == .bus {
			guard let busRoute = data.busRoute else { return }
			self.setupBusJourney(busRoute: busRoute, fare: data.fare)
		} else if data.transactionType == .topUp {
			self.setupTopUp(at: data.from, amount: data.fare)
		} else {
			self.setupTubeJourney(from: data.from, to: data.to, fare: data.fare)
		}
		
		// TODO: Determine if fare is peak or off-peak
	}
	
	func setupCell(from data: Oyster.ContactlessJourney) {
		self.date.text = data.startTime.friendlyFormat()
		self.fareType.alpha = 0.0
		
		if data.from.contains("Bus ") {
			let busRoute = String(data.from.suffix(3))
			self.setupBusJourney(busRoute: busRoute, fare: data.finalFare)
		} else {
			self.setupTubeJourney(from: data.from, to: data.to, fare: data.finalFare)
		}
		
		// TODO: Determine if fare is peak or off-peak
	}
	
	/// Sets up the cell with information about a bus journey
	private func setupBusJourney(busRoute: String, fare: Double) {
		self.from.text = "Bus Route: \(busRoute)"
		self.to.text = "Fare: £" + String(format: "%.2f", fare)
		self.fare.text = ""
	}
	
	/// Sets up the cell with information about a tube journey
	private func setupTubeJourney(from: String, to: String?, fare: Double) {
		self.fare.text = "Fare: £" + String(format: "%.2f", fare)
		
		self.from.text = "From: \(from)"
		if let to = to {
			self.to.text = "To: \(to)"
		} else {
			self.to.text = ""
		}
	}
	
	/// Sets up the cell with information about a Top Up
	private func setupTopUp(at station: String, amount: Double) {
		self.from.text = "Top Up"
		self.to.text = "Location: \(station)"
		self.fare.text = "Amount: £" + String(format: "%.2f", amount)
	}
	
}
