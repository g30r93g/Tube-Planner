//
//  SettingsTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
@testable import TfL_Planner

class SettingsTests: XCTestCase {
	
	func testReset() {
		let settings = Settings()
		settings.reset {
			XCTAssertEqual(settings.oysterUsername, "")
			XCTAssertEqual(settings.oysterPassword, "")
			XCTAssertFalse(settings.isShowingOysterInJourneys)
			XCTAssertFalse(settings.hasCompletedOnboarding)
			XCTAssertEqual(settings.travelcard, .payg)
			XCTAssertEqual(settings.favouriteCardNumber, "")
			XCTAssertFalse(settings.isSavingData)
			XCTAssertTrue(settings.isShowingStatusInJourneys)
			XCTAssertTrue(settings.suggestFavouriteLocations)
			XCTAssertTrue(settings.isFindingFareEstimates)
			XCTAssertEqual(settings.routeStartStations, [])
			XCTAssertTrue(Journeys.shared.journeys.isEmpty)
		}
	}
	
}
