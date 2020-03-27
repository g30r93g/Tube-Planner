//
//  RoutingTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import CoreLocation
import XCTest
@testable import TfL_Planner

class RoutingTests: XCTestCase {
	
	var routing: Routing!
	
	override func setUp() {
		let from = Locations.StationResult(station: Stations.current.find(station: 1000083)!)
		let to = Locations.StationResult(station: Stations.current.find(station: 1000252)!)
		
		self.routing = Routing(from: from, to: to, filters: .standard)
	}
	
	func testInitialiser() {
		let from = Locations.StationResult(station: Stations.current.find(station: 1000083)!)
		let to = Locations.StationResult(station: Stations.current.find(station: 1000252)!)
		
		XCTAssertTrue(routing.from == from && routing.to == to)
	}
	
	func testRoute_getFareEstimate() {
		guard let from = Stations.current.find(station: 1000083) else { XCTFail(); return }
		guard let to = Stations.current.find(station: 1000252) else { XCTFail(); return }
		
		let route = Routing.Route(from: from, to: to, journeyTime: 0, stations: [from, to], instructions: [])
		
		route.getFareEstimate { (fare) in
			XCTAssertNotNil(fare)
			XCTAssert(fare?.cost == 2.4 || fare?.cost == 2.9)
		}
	}
	
	func testRoute_doesSatisfyFilter() {
		guard let from = Stations.current.find(station: 1000083) else { XCTFail(); return }
		guard let to = Stations.current.find(station: 1000252) else { XCTFail(); return }
		
		let route = Routing.Route(from: from, to: to, journeyTime: 0, stations: [from, to], instructions: [])
		
//		XCTAssertTrue(route.doesSatisfyFilter(.standard))
		XCTAssertFalse(route.doesSatisfyFilter(Routing.Filters(isAvoidingZoneOne: true, maxChanges: 1, timePlanning: .none)))
	}
	
	
	func testRouting() {
		self.measure(metrics: [XCTClockMetric()], block: {
			routing.route { (routes) in
				XCTAssertFalse(routes.isEmpty)
			}
		})
	}
	
	func testSelectingRoute() {
		let from = Locations.StationResult(station: Stations.current.find(station: 1000083)!)
		let to = Locations.StationResult(station: Stations.current.find(station: 1000252)!)
		
		let routing = Routing(from: from, to: to, filters: .standard)
		
		routing.route { (routes) in
			XCTAssertFalse(routes.isEmpty)
			
			routing.selectRoute(0)
			
			XCTAssertTrue(routing.selectedRoute() == routes.first)
		}
	}
	
}
