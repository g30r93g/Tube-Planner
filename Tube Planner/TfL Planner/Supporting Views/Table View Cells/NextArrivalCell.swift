//
//  NextArrivalCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 04/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class NextArrivalCell: UITableViewCell {
	
	// MARK: IBOutlet
	@IBOutlet weak private var destination: UILabel!
	@IBOutlet weak private var arrivalTime: UILabel!
	
	// MARK: Methods
	public func setupCell(from data: Arrivals.Arrival) {
		self.destination.text = data.destinationName
		
		if data.timeToStation < 45 {
			self.arrivalTime.text = "Due"
		} else if data.timeToStation >= 45 && data.timeToStation < 120 {
			self.arrivalTime.text = "1 Min"
		} else {
			self.arrivalTime.text = "\(Int(data.timeToStation / 60)) Mins"
		}
	}
	
}
