//
//  RouteStartStationCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 27/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class RouteStartStationCell: RoundUICollectionViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var stationName: UILabel!
	
	// MARK: Properties
	var station: Stations.Station!
	
	// MARK: Methods
	func setupCell(from station: Stations.Station) {
		self.station = station
		self.stationName.text = station.name
	}
	
}
