//
//  PersistenceManagerTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/02/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import XCTest
import MapKit
@testable import TfL_Planner

class PersistenceManagerTests: XCTestCase {
	
	func testblankTest() throws {
		XCTAssert(true)
	}
	
	func testblankTestTwo() throws {
		XCTAssert(true)
	}
	
//	func testReadSaveRecentJourneys() throws {
//		let journeysClass = Journeys()
//		
//		let fromLocation = Locations.StationResult(station: Stations.current.find(station: 1000139)!)
//		let toLocation = Locations.StationResult(station: Stations.current.find(station: 1000254)!)
//		journeysClass.addRecentJourney(journey: Journeys.Journey(from: fromLocation, to: toLocation, date: Date()))
//		
//		let persistenceManager = PersistenceManager()
//		
//		persistenceManager.saveRecentJourneys(journeysClass.journeys)
//		
//		try XCTSkipUnless(journeysClass.journeys == persistenceManager.getRecentJourneys())
//	}
//	
//	func testReadSaveFavouriteLocations() throws {
//		let journeysClass = Journeys()
//		
//		journeysClass.addFavouriteLocation(location: Locations.StreetResult(displayName: "TEST", address: "TEST", placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))), withName: "TEST")
//		
//		let persistenceManager = PersistenceManager()
//		
//		persistenceManager.saveFavouriteLocations(journeysClass.favouriteLocations)
//		
//		try XCTSkipUnless(journeysClass.favouriteLocations == persistenceManager.getFavouriteLocations())
//	}

}
