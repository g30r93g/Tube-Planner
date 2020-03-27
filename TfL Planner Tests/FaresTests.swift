//
//  FaresTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
@testable import TfL_Planner

class FaresTests: XCTestCase {
	
	func testInitialiser() {
		guard let fromStation = Stations().find(station: 1000139) else { XCTFail(); return }
		guard let toStation = Stations().find(station: 1000215) else { XCTFail(); return }
		let startDate = Date()
		
		let fare = Fare(from: fromStation, to: toStation, journeyStartTime: startDate)
		
		XCTAssertEqual(fromStation, fare.from)
		XCTAssertEqual(toStation, fare.to)
		XCTAssertEqual(startDate, fare.date)
	}
	
	func testFindFare() {
		guard let fromStation = Stations().find(station: 1000129) else { XCTFail(); return }
		guard let toStation = Stations().find(station: 1000180) else { XCTFail(); return }
		
		let fare = Fare(from: fromStation, to: toStation)
		
		fare.findFare(fromNaptan: fromStation.naptan.first(where: {$0.starts(with: "940")})!, toNaptan: toStation.naptan.first(where: {$0.starts(with: "940")})!, zones: [.one]) { (fare) in
			guard let fare = fare else { XCTFail(); return }
			
			XCTAssertEqual(fare.cost, 2.40)
		}
	}
	
}
