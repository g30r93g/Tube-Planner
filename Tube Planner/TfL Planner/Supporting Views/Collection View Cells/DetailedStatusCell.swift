//
//  DetailedStatusCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 01/07/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class DetailedStatusCell: RoundUICollectionViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var lineName: UILabel!
	@IBOutlet weak private var line: UIImageView!
	@IBOutlet weak private var status: UILabel!
	@IBOutlet weak private var relevantDateHeight: NSLayoutConstraint!
	@IBOutlet weak private var relevantDate: UILabel!
	@IBOutlet weak private var statusDetails: UILabel!
	
	// MARK: Methods
	func setupCell(from data: Status.StatusInformation, forLine line: Stations.Line, isCurrentStatus: Bool) {
		// Line Icon
		self.line.image = UIImage(named: line.rawValue)

		// Line Name
		self.lineName.text = line.prettyName()
		
		// Relevant Date
		self.relevantDateHeight.constant = 0
		self.relevantDate.alpha = 0
		
		// Line Status
		switch data.severity {
		case .goodService:
			self.status.text = "Good Service"
			self.status.textColor = UIColor(named: "Good Service")
		case .reducedService:
			self.status.text = "Reduced Service"
			self.status.textColor = UIColor.systemOrange
		case .minorDelays:
			self.status.text = "Minor Delays"
			self.status.textColor = UIColor.systemOrange
		case .severeDelays:
			self.status.text = "Severe Delays"
			self.status.textColor = UIColor.systemOrange
		case .partSuspended:
			self.status.text = "Part Suspended"
			self.status.textColor = UIColor.systemRed
		case .suspended:
			self.status.text = "Suspended"
			self.status.textColor = UIColor.systemRed
		case .plannedClosure:
			self.status.text = "Planned Closure"
			self.status.textColor = UIColor.systemOrange
		case .partClosure:
			self.status.text = "Part Closure"
			self.status.textColor = UIColor.systemRed
		case .closed:
			self.status.text = "Closed"
			self.status.textColor = UIColor.systemTeal
		case .specialService:
			self.status.text = "Special Service"
			self.status.textColor = UIColor.systemTeal
		}
		
		if isCurrentStatus {
			// Current status
			if data.severity == .goodService {
				switch line {
				case .overground, .dlr, .tflRail:
					self.statusDetails.text = "There is currently a good service on all routes."
				default:
					self.statusDetails.text = "There is currently a good service."
				}
			} else {
				guard let status = data.information else { return }
				self.statusDetails.text = Status.prettifyStatusInformation(status)
			}
		} else {
			// Future status
			if data.severity == .goodService {
				self.statusDetails.text = "There are no planned closures in the next seven days."
			} else {
				guard let status = data.information else { return }
				self.statusDetails.text = Status.prettifyStatusInformation(status)
				
				guard let validityPeriod = data.validTimePeriods.first else { return }
				self.relevantDate.text = validityPeriod.from.date()
				self.relevantDateHeight.constant = 30
				self.relevantDate.alpha = 1
			}
		}
	}
	
}
