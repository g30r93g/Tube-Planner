//
//  MatchinglineCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 09/09/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class MatchingStationCell: RoundUICollectionViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var stationName: UILabel!
	@IBOutlet weak private var lineOne: UIImageView!
	@IBOutlet weak private var lineTwo: UIImageView!
	@IBOutlet weak private var lineThree: UIImageView!
	@IBOutlet weak private var lineFour: UIImageView!
	@IBOutlet weak private var lineFive: UIImageView!
	@IBOutlet weak private var lineSix: UIImageView!
	
	// MARK: Methods
	func setupCell(from data: Stations.Station) {
		self.stationName.text = data.name
		self.setLineIcons(lines: data.lines)
	}
	
	/// Set the line icons to the relevant image
	private func setLineIcons(lines: [Stations.Line]) {
		self.resetLineIcons()
		
		for line in lines {
			let lineImage = UIImage(named: line.rawValue) ?? UIImage(systemName: "circle.fill")
			
			if self.lineOne.image == nil {
				self.lineOne.image = lineImage
			} else if self.lineTwo.image == nil {
				self.lineTwo.image = lineImage
			} else if self.lineThree.image == nil {
				self.lineThree.image = lineImage
			} else if self.lineFour.image == nil {
				self.lineFour.image = lineImage
			} else if self.lineFive.image == nil {
				self.lineFive.image = lineImage
			} else if self.lineSix.image == nil {
				self.lineSix.image = lineImage
			} else {
				return
			}
		}
	}
	
	/// Reset the line icons to display no image
	private func resetLineIcons() {
		self.lineOne.image = nil
		self.lineTwo.image = nil
		self.lineThree.image = nil
		self.lineFour.image = nil
		self.lineFive.image = nil
		self.lineSix.image = nil
	}
	
}
