//
//  AddFavouriteLocation.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 14/10/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class AddFavouriteLocationCell: RoundUICollectionViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var locationLabel: UILabel!
	@IBOutlet weak private var latitudeLabel: UILabel!
	@IBOutlet weak private var longitudeLabel: UILabel!
	
	// MARK: Methods
	func setupCell(from data: Journeys.FavouriteLocation) {
		self.locationLabel.text = data.name
		self.latitudeLabel.text = "Latitude: \(data.coordinates().latitude)"
		self.longitudeLabel.text = "Longitude: \(data.coordinates().longitude)"
	}
	
}
