//
//  StationsTest.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
import CoreLocation
@testable import TfL_Planner

class StationsTest: XCTestCase {
	
	func testInitialiser() {
		let stationsClass = Stations()
		
		print("Number of stations: \(stationsClass.stations.count)")
		
		XCTAssert(stationsClass.stations.count == 416)
	}
	
	func testFindStationFromIdentifierCode_FindsStation() {
		XCTAssertNotNil(Stations().find(station: 1000139))
	}
	
	func testFindStationFromIdentifierCode_DoesntFindStation() {
		XCTAssertNil(Stations().find(station: 0))
	}
	
	func testStation_retrieveConnection() {
		guard let station = Stations.current.find(station: 1000139) else { XCTFail(); return }
		guard let toStation = Stations.current.find(station: 1000215) else { XCTFail(); return }
		
		XCTAssertNotNil(station.retrieveConnection(to: toStation, on: .jubilee, with: .westbound))
	}
	
	func testStation_retrieveConnections() {
		guard let station = Stations.current.find(station: 1001048) else { XCTFail(); return }
		guard let toStation = Stations.current.find(station: 1000108) else { XCTFail(); return }
		
		XCTAssert(station.retrieveConnections(to: toStation, on: .overground).count == 3)
		XCTAssertTrue(station.retrieveConnections(to: toStation, on: .bakerloo).isEmpty)
	}
	
	func testStation_retrieveOSI() {
		guard let station = Stations.current.find(station: 1001043) else { XCTFail(); return }
		guard let toStation = Stations.current.find(station: 1000035) else { XCTFail(); return }
		
		XCTAssertNotNil(station.retrieveOSI(to: toStation))
	}
	
	func testStation_coordinates() {
		guard let station = Stations.current.find(station: 1000139) else { XCTFail(); return }
		
		// Cannot test since CLLocationCoordinate2D doesn't conform to equatable
//		XCTAssertEqual(station.coordinates(), CLLocationCoordinate2D(latitude: 51.505721, longitude: -0.088873))
		
		_ = XCTSkip()
	}
	
	func testStation_getDoorSide() {
		guard let station = Stations.current.find(station: 1000139) else { XCTFail(); return }
		
		let doorSide = station.getDoorSide(line: .jubilee, direction: .eastbound)
		
		XCTAssertNotNil(doorSide)
		
		if let side = doorSide?.side {
			XCTAssertEqual(side, .right)
		} else {
			XCTFail()
		}
	}
	
	func testConnection_updateStatus() {
		guard let station = Stations.current.find(station: 1000139) else { XCTFail(); return }
		guard let toStation = Stations.current.find(station: 1000215) else { XCTFail(); return }
		
		guard let connection = station.retrieveConnection(to: toStation, on: .jubilee, with: .westbound) else { XCTFail(); return }
		
		connection.updateStatus(to: .goodService)
		XCTAssert(connection.status == .goodService)
		
		connection.updateStatus(to: .closed)
		XCTAssert(connection.status == .closed)
	}
	
	func testDirection_canonical() {
		XCTAssertEqual(Stations.Direction.eastbound.canonical(line: .piccadilly), "outbound")
		XCTAssertEqual(Stations.Direction.northbound.canonical(line: .piccadilly), "")
		XCTAssertEqual(Stations.Direction.southbound.canonical(line: .victoria), "inbound")
	}
	
	func testLine_prettyName() {
		XCTAssertEqual(Stations.Line.victoria.prettyName(), "Victoria")
		XCTAssertEqual(Stations.Line.piccadilly.prettyName(), "Piccadilly")
		XCTAssertEqual(Stations.Line.hammersmithCity.prettyName(), "Hammersmith & City")
	}
	
	func testLine_abbreviation() {
		XCTAssertEqual(Stations.Line.victoria.abbreviation(), "Vic")
		XCTAssertEqual(Stations.Line.piccadilly.abbreviation(), "Pic")
		XCTAssertEqual(Stations.Line.hammersmithCity.abbreviation(), "H&C")
		XCTAssertEqual(Stations.Line.bakerloo.abbreviation(), "Bkr")
	}
	
	func testFindStationFromNaptan_FindsStation() {
		XCTAssertNotNil(Stations().find(naptan: "940GZZLULNB"))
	}
	
	func testFindStationFromNaptan_DoesntFindStation() {
		XCTAssertNil(Stations().find(naptan: "940GZZLUABC"))
	}
	
	func testSearchForStations() {
		let stationsClass = Stations()
		let stationName = "London Bridge"
		let results = stationsClass.search(stationName)
		
		XCTAssert(results.count == 1 && results.first!.ic == 1000139)
	}
	
}
