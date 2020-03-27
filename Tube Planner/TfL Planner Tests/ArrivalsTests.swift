//
//  ArrivalsTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
@testable import TfL_Planner

class ArrivalsTests: XCTestCase {
	
	func testGetArrivals() {
		let arrivalClass = Arrivals(station: Stations.current.find(station: 1000139)!, line: .northern, direction: .northbound)
		
		arrivalClass.getArrivals { (arrivals) in
			XCTAssertFalse(arrivals.isEmpty)
		}
	}
	
}
