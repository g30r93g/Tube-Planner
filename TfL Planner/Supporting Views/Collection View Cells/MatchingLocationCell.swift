//
//  MatchingLocationCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 25/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class MatchingLocationCell: RoundUICollectionViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var locationName: UILabel!
	@IBOutlet weak private var nearestStation: UILabel!
	
	// MARK: Methods
	func setupCell(from data: Locations.POIResult) {
		self.locationName.text = data.displayName
		self.nearestStation.text = "Nearest Station: \(data.nearestStation.name)"
	}
	
	func setupCell(from data: Locations.StreetResult) {
		self.locationName.text = data.displayName
		self.nearestStation.text = "Nearest Station: \(data.nearestStation.name)"
	}
	
}
