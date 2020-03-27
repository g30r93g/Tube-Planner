//
//  StatusTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
@testable import TfL_Planner

class StatusTests: XCTestCase {
	
	func testStatusSeverity() {
		XCTAssertGreaterThan(Status.StatusSeverity.goodService, Status.StatusSeverity.closed)
	}
	
	func testUpdateLastFetch() {
		let status = Status()
		
		XCTAssertNil(status.lastUpdate)
		
		status.updateLastFetchDate()
		
		XCTAssertNotNil(status.lastUpdate)
	}
	
	// func updateStatus(forceUpdate:_, completion:_)
	func testUpdateStatus() {
		Status().updateStatus { (status) in
			do {
				try XCTSkipIf(!Networking.connection.connectionIsAvailable, "No network connection")
				
				let correctNumberOfStatuses = status.count == 14
				XCTAssert(correctNumberOfStatuses)
			} catch let error {
				print(error)
			}
		}
	}
	
	// static func prettifyStatusInformation(_ information: String) -> String
	func testPrettifyingStatusInformation() {
		let testString = "Line Name: This is a test.   "
		let resultString = "This is a test."
		
		XCTAssert(Status.prettifyStatusInformation(testString) == resultString)
	}
	
}
