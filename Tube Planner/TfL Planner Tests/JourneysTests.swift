//
//  JourneysTest.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
import MapKit
@testable import TfL_Planner

class JourneysTest: XCTestCase {
	
	func testAddRecentJourney() {
		let journeysClass = Journeys()
		let numberOfJourneys = journeysClass.journeys.count
		
		let fromLocation = Locations.StationResult(station: Stations.current.find(station: 1000139)!)
		let toLocation = Locations.StationResult(station: Stations.current.find(station: 1000254)!)
		journeysClass.addRecentJourney(journey: Journeys.Journey(from: fromLocation, to: toLocation, date: Date()))
		
		let newNumberOfJourneys = journeysClass.journeys.count
		
		XCTAssert(newNumberOfJourneys - numberOfJourneys == 1)
	}
	
	func testAddDuplicateRecentJourneys() {
		let journeysClass = Journeys()
		let fromLocation = Locations.StationResult(station: Stations.current.find(station: 1000139)!)
		let toLocationFirst = Locations.StationResult(station: Stations.current.find(station: 1000254)!)
		let toLocationSecond = Locations.StationResult(station: Stations.current.find(station: 1000179)!)
		
		journeysClass.addRecentJourney(journey: Journeys.Journey(from: fromLocation, to: toLocationFirst, date: Date()))
		journeysClass.addRecentJourney(journey: Journeys.Journey(from: fromLocation, to: toLocationSecond, date: Date()))
		journeysClass.addRecentJourney(journey: Journeys.Journey(from: fromLocation, to: toLocationFirst, date: Date()))
		let numberOfJourneys = journeysClass.journeys.count
		
		XCTAssert(numberOfJourneys == 2)
	}
	
	func testAddFavouriteLocation() {
		let journeysClass = Journeys()
		
		let numberOfFavouriteLocations = journeysClass.favouriteLocations.count
		
		journeysClass.addFavouriteLocation(location: Locations.StreetResult(displayName: "TEST", address: "TEST", placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))), withName: "TEST")
		
		let newNumberOfFavouriteLocations = journeysClass.favouriteLocations.count
		
		XCTAssert(newNumberOfFavouriteLocations - numberOfFavouriteLocations == 1)
	}
	
	// func clearRecentJourneys()
	func testClearRecentJourney() {
		let journeysClass = Journeys()
		
		let fromLocation = Locations.StationResult(station: Stations.current.find(station: 1000139)!)
		let toLocation = Locations.StationResult(station: Stations.current.find(station: 1000254)!)
		journeysClass.addRecentJourney(journey: Journeys.Journey(from: fromLocation, to: toLocation, date: Date()))
		
		let initialCount = journeysClass.journeys.count
		XCTAssert(initialCount > 0)
		
		journeysClass.clearRecentJourneys()
		
		let finalCount = journeysClass.journeys.count
		XCTAssert(initialCount > finalCount)
		XCTAssert(finalCount == 0)
	}
	
	func testRemoveFavouriteLocation() {
		let journeysClass = Journeys()
		
		journeysClass.addFavouriteLocation(location: Locations.StreetResult(displayName: "TEST", address: "TEST", placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))), withName: "TEST")
		guard let favouriteLocation = journeysClass.favouriteLocations.first else { XCTFail(); return }
		
		let initialCount = journeysClass.favouriteLocations.count
		
		XCTAssertTrue(initialCount > 0)
		
		journeysClass.removeFavouriteLocation(favouriteLocation)
	
		XCTAssert(initialCount > journeysClass.favouriteLocations.count)
		XCTAssertEqual(initialCount - 1, journeysClass.favouriteLocations.count)
	}
	
}
