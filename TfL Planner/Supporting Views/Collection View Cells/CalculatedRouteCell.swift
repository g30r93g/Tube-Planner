//
//  CalculatedRouteCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 10/09/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class CalculatedRouteCell: RoundUICollectionViewCell {
	
	// MARK: Properties
	var loadingAnimationTimer: Timer!
	
	// MARK: IBOutlets
	@IBOutlet weak private var cellIndicator: UIPageControl!
	@IBOutlet weak private var journeyTimeTop: NSLayoutConstraint!
	@IBOutlet weak private var journeyTime: UILabel!
	@IBOutlet weak private var timePlanningType: UILabel!
	@IBOutlet weak private var timePlanning: UILabel!
	@IBOutlet weak private var horizontalSeparator: UIView!
	@IBOutlet weak private var fare: RoundLabel!
	@IBOutlet weak private var outline: RouteOutline!
	
	// MARK: Methods
	func setupCell(from data: Routing.Route, numberOfRoutes: Int, displayingRoute routeNumber: Int, timePlanning: Routing.TimePlanning) {
		self.cellIndicator.numberOfPages = numberOfRoutes
		self.cellIndicator.currentPage = routeNumber
		
		self.fare.alpha = 0
		self.horizontalSeparator.alpha = 0
		self.journeyTimeTop.constant = 15
		
		self.journeyTime.text = "\(data.journeyTime / 60)"
		self.outline.createOutline(from: data.instructions)
		
		self.getFare(from: data)
		
		if let leaveAt = timePlanning.leaveAt {
			let arrivalTime = leaveAt.addingTimeInterval(TimeInterval(data.journeyTime))
			self.timePlanningType.text = "Arriving at"
			self.timePlanning.text = " \(arrivalTime.time())"
		} else if let arriveBy = timePlanning.arriveBy {
			let leaveByTime = arriveBy.addingTimeInterval(TimeInterval(-1 * data.journeyTime))
			self.timePlanningType.text = "Leave by"
			self.timePlanning.text = " \(leaveByTime.time())"
		} else {
			self.timePlanningType.text = ""
			self.timePlanning.text = ""
		}
	}
	
	private func getFare(from data: Routing.Route) {
		data.getFareEstimate { (fare) in
			guard let fare = fare else { DispatchQueue.main.async { self.fare.alpha = 0 }; return }
			
			self.showFare(fare)
		}
	}
	
	private func showFare(_ fare: Fare.Fare) {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
				self.journeyTimeTop.constant = 2
				
				self.layoutIfNeeded()
			}) { (_) in
				UIView.animate(withDuration: 0.4) {
					self.horizontalSeparator.alpha = 1
					self.fare.alpha = 1
					self.fare.text = "£\(String(format: "%.2f", fare.cost))"
				}
			}
		}
	}
	
}
