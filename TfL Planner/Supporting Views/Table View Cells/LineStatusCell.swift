//
//  LineStatusself.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 30/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class LineStatusCell: UITableViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var lineIcon: RoundImageView!
	@IBOutlet weak private var lineNameLabel: UILabel!
	@IBOutlet weak private var lineStatusLabel: UILabel!
	
	// MARK: Methods
	func setupCell(from data: Status.LineStatus) {
		// Line Icon
		self.lineIcon.image = UIImage(named: data.line.rawValue)
		
		// Line Name
		self.lineNameLabel.text = data.line.prettyName()
		
		// Line Status
		switch data.currentStatuses.sorted().first {
		case .goodService:
			self.lineStatusLabel.text = "Good Service"
			self.lineStatusLabel.textColor = UIColor.systemGreen
		case .reducedService:
			self.lineStatusLabel.text = "Reduced Service"
			self.lineStatusLabel.textColor = UIColor.systemOrange
		case .minorDelays:
			self.lineStatusLabel.text = "Minor Delays"
			self.lineStatusLabel.textColor = UIColor.systemOrange
		case .severeDelays:
			self.lineStatusLabel.text = "Severe Delays"
			self.lineStatusLabel.textColor = UIColor.systemOrange
		case .partSuspended:
			self.lineStatusLabel.text = "Part Suspended"
			self.lineStatusLabel.textColor = UIColor.systemRed
		case .suspended:
			self.lineStatusLabel.text = "Suspended"
			self.lineStatusLabel.textColor = UIColor.systemRed
		case .plannedClosure:
			self.lineStatusLabel.text = "Planned Closure"
			self.lineStatusLabel.textColor = UIColor.systemOrange
		case .partClosure:
			self.lineStatusLabel.text = "Part Closure"
			self.lineStatusLabel.textColor = UIColor.systemRed
		case .closed:
			self.lineStatusLabel.text = "Closed"
			self.lineStatusLabel.textColor = UIColor.systemTeal
		case .specialService:
			self.lineStatusLabel.text = "Special Service"
			self.lineStatusLabel.textColor = UIColor.systemTeal
		case .none:
			break
		}
	}
	
}
