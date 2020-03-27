//
//  NetworkingTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
@testable import TfL_Planner

class NetworkingTests: XCTestCase {
	
	func testIsSavingData() {
		Settings().changeDataSaving(to: false)
		
		XCTAssertFalse(Settings().isSavingData)
	}
	
	func testConnectionIsAvailable() {
		XCTAssertTrue(Networking().connectionIsAvailable)
	}
	
	func testIsPermitted() {
		XCTAssertTrue(Networking().connectionIsAvailable)
		XCTAssertTrue(Networking().isPermitted)
	}
	
}
