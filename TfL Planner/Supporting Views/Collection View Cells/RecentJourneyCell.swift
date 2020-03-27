//
//  RecentJourneyCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 30/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class RecentJourneyCell: RoundUICollectionViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var from: UILabel!
	@IBOutlet weak private var to: UILabel!
	
	// MARK: Methods
	func setupCell(from data: Journeys.Journey) {
		self.from.text = data.from.displayName
		self.to.text = data.to.displayName
	}
	
}
