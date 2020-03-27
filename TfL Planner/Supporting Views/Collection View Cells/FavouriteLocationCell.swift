//
//  FavouriteLocationCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 30/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class FavouriteLocationCell: RoundUICollectionViewCell {

	// MARK: IBOutlets
	@IBOutlet weak private var locationName: UILabel!
	
	// MARK: Methods
	func setupCell(from data: Journeys.FavouriteLocation) {
		self.locationName.text = data.name
		self.locationName.textColor = UIColor.white
		self.backgroundColor = UIColor(named: "Text Field Background")
	}
	
	func setupForAddingLocation() {
		self.locationName.text = "Add New Location"
		self.backgroundColor = UIColor(named: "Accent 2")
	}

}
