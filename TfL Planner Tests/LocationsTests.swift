//
//  LocationsTests.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 23/02/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import XCTest
import MapKit
@testable import TfL_Planner

class LocationsTest: XCTestCase {

	let locations = Locations()
	
	func testInitialiser() {
		XCTAssertTrue(!locations.pointsOfInterests.isEmpty)
	}
	
	func testFindPOIs() {
		let searchValue = "Emirates Stadium"
		
		let matchingPOIs = locations.findPOIs(matching: searchValue)
		
		XCTAssertTrue(matchingPOIs.count == 1)
	}

}
