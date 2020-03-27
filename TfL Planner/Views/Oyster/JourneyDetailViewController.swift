//
//  JourneyDetailViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 20/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class JourneyDetailViewController: UIViewController {

	// MARK: IBOutlets
	@IBOutlet weak private var journeyDate: UILabel!
	@IBOutlet weak private var fromStation: UILabel!
	@IBOutlet weak private var toStation: UILabel!
	@IBOutlet weak private var fare: UILabel!
	@IBOutlet weak private var overviewHeight: NSLayoutConstraint!
	@IBOutlet weak private var tapsTable: UITableView!
	
	// MARK: Properties
	var oysterJourney: Oyster.OysterJourney?
	var contactlessJourney: Oyster.ContactlessJourney?
	
	// MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		
		self.setupView()
    }
	
	// MARK: Methods
	private func setupView() {
		self.overviewHeight.constant = 120
		if oysterJourney != nil {
			self.setupOysterJourney()
		} else if contactlessJourney != nil {
			self.setupContactlessJourney()
		} else {
			return
		}
		
		self.tapsTable.reloadData()
	}
	
	private func setupOysterJourney() {
		guard let oysterJourney = self.oysterJourney else { return }
		
		self.journeyDate.text = oysterJourney.startTime.friendlyFormat()
		self.fromStation.text = "From: \(oysterJourney.from)"
		
		if oysterJourney.transactionType == .bus {
			self.setupBusJourney(busRoute: oysterJourney.busRoute!, fare: oysterJourney.fare)
		} else if oysterJourney.transactionType == .topUp {
			self.setupTopUp(at: oysterJourney.from, amount: oysterJourney.fare)
		} else {
			self.setupTubeJourney(from: oysterJourney.from, to: oysterJourney.to, fare: oysterJourney.fare)
		}
	}
	
	private func setupContactlessJourney() {
		guard let contactlessJourney = self.contactlessJourney else { return }
		
		self.journeyDate.text = contactlessJourney.startTime.friendlyFormat()
		self.fromStation.text = "From: \(contactlessJourney.from)"
		
		if contactlessJourney.from.contains("Bus ") {
			let busRoute = String(contactlessJourney.from.suffix(3))
			self.setupBusJourney(busRoute: busRoute, fare: contactlessJourney.finalFare)
		} else {
			self.setupTubeJourney(from: contactlessJourney.from, to: contactlessJourney.to, fare: contactlessJourney.finalFare)
		}
	}
	
	/// Sets up the cell with information about a bus journey
	private func setupBusJourney(busRoute: String, fare: Double) {
		self.fromStation.text = "Bus Route: \(busRoute)"
		self.toStation.text = "Fare: £" + String(format: "%.2f", fare)
		self.fare.text = ""
	}
	
	/// Sets up the cell with information about a tube journey
	private func setupTubeJourney(from: String, to: String?, fare: Double) {
		self.fare.text = "Fare: £" + String(format: "%.2f", fare)
		
		self.fromStation.text = "From: \(from)"
		if let to = to {
			self.toStation.text = "To: \(to)"
			self.overviewHeight.constant = 150
		} else {
			self.toStation.text = ""
		}
	}
	
	/// Sets up the cell with information about a Top Up
	private func setupTopUp(at station: String, amount: Double) {
		self.fromStation.text = "Top Up"
		self.toStation.text = "Location: \(station)"
		self.fare.text = "Amount: £" + String(format: "%.2f", amount)
	}
	
	// MARK: IBActions
	@IBAction private func dismissTapped(_ sender: UIButton) {
		self.dismiss(animated: true, completion: nil)
	}

}

extension JourneyDetailViewController: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let oysterJourney = oysterJourney {
			return oysterJourney.taps.count
		} else if let contactlessJourney = contactlessJourney {
			return contactlessJourney.taps.count
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Tap", for: indexPath) as! TapCell
		
		if let oysterJourney = oysterJourney {
			cell.setupCell(from: oysterJourney.taps[indexPath.row])
		} else if let contactlessJourney = contactlessJourney {
			cell.setupCell(from: contactlessJourney.taps[indexPath.row])
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 60
	}
	
}
