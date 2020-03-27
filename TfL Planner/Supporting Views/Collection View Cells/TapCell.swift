//
//  TapCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 20/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class TapCell: UITableViewCell {
	
	// MARK: IBOutlet
	@IBOutlet weak private var time: UILabel!
	@IBOutlet weak private var icon: RoundImageView!
	@IBOutlet weak private var tapDescription: UILabel!
	
	// MARK: Methods
	func setupCell(from data: Oyster.OysterTaps) {
		self.time.text = data.time.time()
		self.tapDescription.text = data.description
		
		switch data.validationType {
		case .entry, .exit, .validation:
			self.icon.image = UIImage(named: "Yellow Reader")
		case .topUp:
			self.icon.image = UIImage(named: "Oyster")
		case .busEntry:
			self.icon.image = UIImage(named: "Bus")
		case .pinkRouteValidator:
			self.icon.image = UIImage(named: "Pink Reader")
		}
	}
	
	func setupCell(from data: Oyster.ContactlessTaps) {
		self.time.text = data.time.time()
		self.tapDescription.text = data.description
		
		switch data.validationType {
		case .entry, .exit, .validation:
			self.icon.image = UIImage(named: "Contactless")
		case .pinkRouteValidator:
			self.icon.image = UIImage(named: "Pink Reader")
		}
	}
	
}
