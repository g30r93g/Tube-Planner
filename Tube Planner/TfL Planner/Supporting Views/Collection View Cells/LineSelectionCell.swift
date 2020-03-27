//
//  SmallLineCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 27/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class SmallLineCell: RoundUICollectionViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var lineImage: RoundImageView!
	@IBOutlet weak private var lineName: UILabel!
	
	// MARK: Properties
	var line: Stations.Line!
	
	// MARK: Methods
	func setupCell(from line: Stations.Line) {
		self.line = line
		
		self.lineName.text = line.prettyName()
		self.lineImage.image = UIImage(named: line.rawValue)
		
		if Settings().commuteLines.contains(line) {
			self.select()
		} else {
			self.unselect()
		}
	}
	
	func select() {
		UIView.animate(withDuration: 0.2) {
			self.backgroundColor = UIColor(named: self.line.prettyName())?.darken()
		}
	}
	
	func unselect() {
		UIView.animate(withDuration: 0.2) {
			self.backgroundColor = UIColor(named: "Cells")
		}
	}
	
}
