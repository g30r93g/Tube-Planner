//
//  JourneyPlannerFilterViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 27/01/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class JourneyPlannerFilterViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var blur: UIVisualEffectView!
	@IBOutlet weak private var avoidsZoneOne: UISwitch!
	@IBOutlet weak private var maxChanges: UILabel!
	@IBOutlet weak private var decrementMaxChanges: UIButton!
	@IBOutlet weak private var incrementMaxChanges: UIButton!
	@IBOutlet weak private var timeNow: UIButton!
	@IBOutlet weak private var leaveAtArriveBySegment: UISegmentedControl!
	@IBOutlet weak private var timeSelector: UIDatePicker!
	
	// MARK: Properties
	var isAvoidingZoneOne: Bool = false
	var maxChangesValue: Int = 3
	var timePlanning: Routing.TimePlanning = .none
	
	var completionHandler: ((Routing.Filters) -> Void)!
	var isNow: Bool = true
	
	// MARK: View Controller Life Cycle
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.setupView()
	}
	
	// MARK: Methods
	private func setupView() {
		self.setupTimePicker()
		self.setupFilters()
	}
	
	private func setupFilters() {
		if let leaveAt = timePlanning.leaveAt {
			self.leaveAtArriveBySegment.selectedSegmentIndex = 0
			self.timeSelector.date = leaveAt
		} else if let arriveBy = timePlanning.arriveBy {
			self.leaveAtArriveBySegment.selectedSegmentIndex = 1
			self.timeSelector.date = arriveBy
		} else {
			self.timeSelector.date = Date()
		}
		
		self.updateFilters()
	}
	
	private func updateFilters() {
		self.avoidsZoneOne.isOn = self.isAvoidingZoneOne
		self.maxChanges.text = "\(self.maxChangesValue)"
	}
	
	private func updateMaxChanges(adding value: Int) {
		self.maxChangesValue += value
		
		if self.maxChangesValue <= 1 {
			self.disableDecrement()
		} else {
			self.enableDecrement()
		}
		
		if self.maxChangesValue >= 5 {
			self.disableIncrement()
		} else {
			self.enableIncrement()
		}
		
		self.updateFilters()
	}
	
	private func disableIncrement() {
		self.incrementMaxChanges.isEnabled = false
	}
	
	private func enableIncrement() {
		self.incrementMaxChanges.isEnabled = true
	}
	
	private func disableDecrement() {
		self.decrementMaxChanges.isEnabled = false
	}
	
	private func enableDecrement() {
		self.decrementMaxChanges.isEnabled = true
	}
	
	private func setTimeToNow() {
		self.timeSelector.date = Date()
		self.isNow = true
		self.timePlanning = .none
		
		self.updateFilters()
	}
	
	private func setupTimePicker() {
		self.timeSelector.minimumDate = Date()
		self.timeSelector.maximumDate = Date().tomorrow(hour: 23, minute: 59, second: 0)
	}
	
	// MARK: IBActions
	@IBAction private func dismissTapped(_ sender: UIButton) {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction private func setFilter() {
		var plan: Routing.TimePlanning {
			if self.isNow {
				return .none
			} else {
			return Routing.TimePlanning(leaveAt: self.leaveAtArriveBySegment.selectedSegmentIndex == 0 ? self.timeSelector.date : nil,
										arriveBy: self.leaveAtArriveBySegment.selectedSegmentIndex == 0 ? nil : self.timeSelector.date)
			}
		}
		print(" ** \(self.timeSelector.date) **--** \(plan.leaveAt) • \(plan.arriveBy)")
		
		let filter = Routing.Filters(isAvoidingZoneOne: self.avoidsZoneOne.isOn, maxChanges: self.maxChangesValue, timePlanning: plan)
		
		self.completionHandler(filter)
	}
	
	@IBAction private func avoidZoneOneToggled(_ sender: UISwitch) { }
	
	@IBAction private func nowTapped(_ sender: UIButton) {
		self.setTimeToNow()
	}
	
	@IBAction private func maxChangesChanged(_ sender: UIButton) {
		self.updateMaxChanges(adding: sender == incrementMaxChanges ? 1 : -1)
	}
	
	@IBAction private func timeSelectorValueChanged(_ sender: UIDatePicker) {
		self.isNow = false
	}
	
}
