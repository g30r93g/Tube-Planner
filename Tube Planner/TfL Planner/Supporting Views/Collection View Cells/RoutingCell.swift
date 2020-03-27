//
//  RoutingCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 03/10/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class RoutingCell: RoundUICollectionViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var instructionIndicator: UIPageControl!
	@IBOutlet weak private var lineName: UILabel!
	@IBOutlet weak private var lineImage: RoundImageView!
	@IBOutlet weak private var direction: UILabel!
	@IBOutlet weak private var separator: UIView!
	@IBOutlet weak private var waitRide: UILabel!
	@IBOutlet weak private var stationName: UILabel!
	@IBOutlet weak private var timing: UILabel!
	@IBOutlet weak private var carriageDoor: UILabel!
	
	// MARK: Methods
	func setupCell(from instruction: Routing.Instruction, instructionNumber: Int, numberOfInstructions: Int) {
		self.instructionIndicator.numberOfPages = numberOfInstructions
		self.instructionIndicator.currentPage = instructionNumber
		
		self.carriageDoor.text = ""
		
		self.waitRide.alpha = 1
		self.stationName.alpha = 1
		self.timing.alpha = 1
		self.separator.alpha = 1
		
		switch instruction.type {
		case .walking:
			self.lineImage.image = UIImage(named: "Walk")

			self.lineName.text = "Walk to"
			
			if let walkingDestination = instruction.walkingTo {
				self.direction.text = walkingDestination.displayName
			}
			
			self.waitRide.alpha = 0
			self.stationName.alpha = 0
			self.timing.alpha = 0
			self.separator.alpha = 0
		case .platform:
			if instructionNumber == 0 || instructionNumber == 1 {
				self.waitRide.text = "Wait at"
			} else {
				self.waitRide.text = "Change at"
			}
			
			if let station = instruction.station {
				self.stationName.text = station.name
			}
			
			self.lineName.text = instruction.line!.prettyName()
			self.lineImage.image = UIImage(named: instruction.line!.rawValue)
			self.direction.text = instruction.direction!.rawValue
			
			self.timing.alpha = 0
		case .route:
			if let numberOfStations = instruction.stations?.count {
				self.waitRide.text = numberOfStations <= 2 ? "Ride 1 stop to" : "Ride \(numberOfStations - 1) stops to"
			}
			
			self.timing.alpha = 1
			self.timing.text = "\(instruction.instructionTime / 60) mins"
			
			if let toStation = instruction.to {
				self.stationName.text = toStation.name
			}
			
			self.lineName.text = instruction.line!.prettyName()
			self.lineImage.image = UIImage(named: instruction.line!.rawValue)
			self.direction.text = instruction.direction!.rawValue
			
			if let doorSide = instruction.stations!.last?.getDoorSide(line: instruction.line!, direction: instruction.direction!) {
				switch doorSide.side {
				case .left:
					self.carriageDoor.text = "Doors open on the left."
				case .right:
					self.carriageDoor.text = "Doors open on the right."
				case .either:
					self.carriageDoor.text = "Doors open on either side."
				case .both:
					self.carriageDoor.text = "Doors open on both sides."
				case .none:
					break
				}
			}
		case .exit:
			self.waitRide.text = "Exit at"
			self.timing.text = ""
			self.timing.alpha = 0
			
			if let station = instruction.station {
				self.stationName.text = station.name
			}
			
			self.lineName.text = instruction.line!.prettyName()
			self.lineImage.image = instruction.line!.prettyName().contains("Walk") ? UIImage(named: "Walk") : UIImage(named: instruction.line!.rawValue)
			self.direction.text = instruction.direction! == .direction ? "" : instruction.direction!.rawValue
		}
	}
	
}
