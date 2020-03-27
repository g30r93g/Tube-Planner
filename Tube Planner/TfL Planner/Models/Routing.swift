//
//  Routing.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 05/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import CoreLocation

final class Routing {
	
	// MARK: Properties
	let from: Locations.LocationResult
	let to: Locations.LocationResult
	let filters: Filters
	
	// Instance of the graph and initialises routes
	private var isRouting: Bool = false
	private(set) var graph: Graph = Graph()
	private(set) var routes: [Route] = [] {
		didSet {
			self.routes.sort()
		}
	}
	private var selectedRouteIndex: Int?
	
	// MARK: Initialiser
	init(from: Locations.LocationResult, to: Locations.LocationResult, filters: Filters) {
		self.from = from
		self.to = to
		self.filters = filters
	}
	
	// MARK: Structs
	/// Represents a potential route between two stations
	class Route: Comparable {
		let from: Stations.Station
		let to: Stations.Station
		let journeyTime: Int
		let timePlanning: TimePlanning?
		
		let stations: [Stations.Station]
		let instructions: [Instruction]
		
		var fareEstimate: Double
		
		// MARK: Initialiser
		init(from: Stations.Station, to: Stations.Station, journeyTime: Int, timePlanning: TimePlanning? = nil, stations: [Stations.Station], instructions: [Instruction]) {
			self.from = from
			self.to = to
			self.journeyTime = journeyTime
			self.stations = stations
			self.instructions = instructions
			self.timePlanning = timePlanning
			
			self.fareEstimate = 0.0
		}
		
		// MARK: Methods
		func getFareEstimate(completion: @escaping(Fare.Fare?) -> Void) {
			var fromNaptan: String {
				guard let firstInstruction = instructions.first(where: {$0.type != .walking}) else { return self.from.naptan[0] }
				switch firstInstruction.line {
				case .overground, .tflRail:
					return self.from.naptan.first(where: {$0.contains("910")}) ?? self.from.naptan[0]
				default:
					return self.from.naptan.first(where: {$0.contains("940")}) ?? self.from.naptan[0]
				}
			}
			
			var toNaptan: String {
				guard let lastInstruction = instructions.first(where: {$0.type != .walking}) else { return self.from.naptan[0] }
				switch lastInstruction.line {
				case .overground, .tflRail:
					return self.to.naptan.first(where: {$0.contains("910")}) ?? self.to.naptan[0]
				default:
					return self.to.naptan.first(where: {$0.contains("940")}) ?? self.to.naptan[0]
				}
			}
			
			Fare(from: self.from, to: self.to).findFare(fromNaptan: fromNaptan, toNaptan: toNaptan, zones: self.stations.map({$0.zone})) { (fare) in
				guard let determinedFare = fare else { completion(fare); return }
				self.fareEstimate = determinedFare.cost
				
				completion(determinedFare)
			}
		}
		
		public func doesSatisfyFilter(_ filters: Routing.Filters) -> Bool {
			// Determine if avoids zone one
			if self.stations.compactMap({$0.zone}).contains(.one) && filters.isAvoidingZoneOne { return false }
			
			// Determine if satisfies max interchange filter
			var numberOfInterchanges = self.instructions.filter({$0.type == .route}).count - 1
			if numberOfInterchanges < 0 { numberOfInterchanges = 0 }
			
			if numberOfInterchanges > filters.maxChanges {
				return false
			}
			
			// Determine if route will satisfy 'hideWhenPoorStatus'
			if Settings().hidingRoutesWithPoorStatus && !self.routeHasGoodService() {
				return false
			}
			
			// Determine if route will satisfy time constraints
			if let arriveBy = filters.timePlanning.arriveBy {
				return arriveBy.addingTimeInterval(TimeInterval(-1 * self.journeyTime)) > Date()
			} else {
				return true
			}
		}

		private func routeHasGoodService() -> Bool {
			let statuses = self.instructions.filter({$0.type == .route}).flatMap({$0.connections!}).map({$0.status}).sorted()
			
			if statuses.isEmpty { return true }
			
			return (statuses.first ?? .goodService) == .goodService
		}
		
		
		// MARK: Comparable
		static func == (lhs: Routing.Route, rhs: Routing.Route) -> Bool {
			return lhs.from == rhs.from && lhs.to == rhs.to && lhs.stations == rhs.stations
		}
		
		static func < (lhs: Routing.Route, rhs: Routing.Route) -> Bool {
			switch Settings().preferredRoutingSuggestion {
			case .fastest:
				return lhs.journeyTime < rhs.journeyTime
			case .fewestChanges:
				return lhs.instructions.filter({$0.type == .route}).count - 1 < rhs.instructions.filter({$0.type == .route}).count - 1
			case .lowestFare:
				return lhs.fareEstimate < rhs.fareEstimate
			case .leastWalking:
				let lhsWalking = lhs.instructions.filter({$0.type == .route}).map({$0.instructionTime}).reduce(lhs.journeyTime, {$0 - $1})
				let rhsWalking = rhs.instructions.filter({$0.type == .route}).map({$0.instructionTime}).reduce(rhs.journeyTime, {$0 - $1})
				return lhsWalking < rhsWalking
			}
		}
	}
	
	// MARK: Structs
	struct Filters {
		var isAvoidingZoneOne: Bool
		var maxChanges: Int
		var timePlanning: TimePlanning
		
		static let standard: Filters = Filters(isAvoidingZoneOne: false, maxChanges: 3, timePlanning: .none)
	}
	
	struct TimePlanning: Equatable {
		var leaveAt: Date?
		var arriveBy: Date?
		
		static let none = TimePlanning()
		
		// MARK: Equatable
		static func == (lhs: TimePlanning, rhs: TimePlanning) -> Bool {
			return lhs.leaveAt == rhs.leaveAt && lhs.arriveBy == rhs.arriveBy
		}
	}
	
	/// Represents an instruction to be followed
	struct Instruction {
		// All Types
		let type: InstructionType
		let instructionTime: Int
		
		// Walking & OSI
		let fromLocation: CLLocationCoordinate2D?
		let toLocation: CLLocationCoordinate2D?
		
		// Walking, Platform, Interchange & Exit Instruction
		let walkingFrom: Locations.LocationResult?
		let walkingTo: Locations.LocationResult?
		
		// Platform & Exit Instruction
		let line: Stations.Line?
		let direction: Stations.Direction?
		let station: Stations.Station?
		
		// Route Instruction
		let from: Stations.Station?
		let to: Stations.Station?
		let stations: [Stations.Station]?
		let connections: [Stations.Connection]?
		
		// MARK: Initialisers
		// Walking & OSI
		init(type: InstructionType, from: CLLocationCoordinate2D? = nil, to: CLLocationCoordinate2D? = nil, fromResult: Locations.LocationResult? = nil, toResult: Locations.LocationResult? = nil, instructionTime: Int) {
			self.type = type
			self.instructionTime = instructionTime
			self.walkingFrom = fromResult
			self.walkingTo = toResult
			
			self.fromLocation = from
			self.toLocation = to
			
			self.line = nil
			self.direction = nil
			self.from = nil
			self.to = nil
			self.stations = nil
			self.station = nil
			self.connections = nil
		}
		
		// Platform and Exit
		init(type: InstructionType, station: Stations.Station, line: Stations.Line, direction: Stations.Direction) {
			self.type = type
			self.line = line
			self.direction = direction
			self.station = station
			self.instructionTime = 0
			
			self.from = nil
			self.to  = nil
			self.stations = nil
			self.fromLocation = nil
			self.toLocation = nil
			self.walkingFrom = nil
			self.walkingTo = nil
			self.connections = nil
		}
		
		// Route
		init(type: InstructionType, stations: [Stations.Station], connections: [Stations.Connection], line: Stations.Line, direction: Stations.Direction, instructionTime: Int) {
			self.type = type
			self.stations = stations
			self.connections = connections
			self.from = stations.first!
			self.to = stations.last!
			self.line = line
			self.direction = direction
			self.instructionTime = instructionTime
			
			self.fromLocation = nil
			self.toLocation = nil
			self.station = nil
			self.walkingFrom = nil
			self.walkingTo = nil
		}
	}
	
	// MARK: Enums
	/// Indicates the type of instruction
	enum InstructionType {
		/// Walking directions to a location
		case walking
		
		/// Waiting for train on a platform
		case platform
		
		/// Riding on train
		case route
		
		/// Leaving station
		case exit
	}
	
	/// Indicates the type of heuristic used
	enum Heuristic: String {
		case fastest
		case fewestChanges
		case lowestFare
		case leastWalking
	}
	
	// MARK: Routing Methods
	/// Handles adding line status to graph
	private func addLineStatus(completion: @escaping() -> Void) {
		if Settings().hidingRoutesWithPoorStatus {
			self.graph.applyLineStatus {
				completion()
			}
		} else {
			completion()
		}
	}
	
	/// Begin routing between two points
	public func route(completion: @escaping([Route]) -> Void) {
		var startStation: Stations.Station!
		var endStation: Stations.Station!
		
		var walkingToStartInstruction: Instruction?
		var walkingFromEndInstruction: Instruction?
		
		// Add walking instruction to start station
		walkingStart:
		if let fromLocation = from as? Locations.StreetResult {
			// Remember to add walking instruction at start
			startStation = UserLocation.current.getNearestStations(to: fromLocation.coordinates, limit: 1).first!.station
			
			guard let userLocation = UserLocation.current.updateLocation() else { break walkingStart }
			
			walkingToStartInstruction = Instruction(type: .walking, from: userLocation.coordinate, to: startStation.coordinates(), fromResult: fromLocation, toResult: Locations.StationResult(station: startStation), instructionTime: 0)
		} else if let fromLocation = from as? Locations.POIResult {
			startStation = fromLocation.pointOfInterest.nearestStation
			
			guard let userLocation = UserLocation.current.updateLocation() else { break walkingStart }
			
			walkingToStartInstruction = Instruction(type: .walking, from: userLocation.coordinate, to: startStation.coordinates(), fromResult: fromLocation, toResult: Locations.StationResult(station: startStation), instructionTime: 0)
		} else {
			guard let start = from as? Locations.StationResult else { fatalError() }
			startStation = start.station
		}
		
		// Add walking instruction from end station
		walkingEnd:
		if let toLocation = to as? Locations.StreetResult {
			// Remember to add walking instruction at end
			endStation = UserLocation.current.getNearestStations(to: toLocation.coordinates, limit: 1).first!.station
			
			guard let userLocation = UserLocation.current.updateLocation() else { break walkingEnd }
			
			walkingFromEndInstruction = Instruction(type: .walking, from: userLocation.coordinate, to: startStation.coordinates(), fromResult: Locations.StationResult(station: endStation), toResult: toLocation, instructionTime: 0)
		} else if let toLocation = to as? Locations.POIResult {
			endStation = toLocation.pointOfInterest.nearestStation
			
			guard let userLocation = UserLocation.current.updateLocation() else { break walkingEnd }
			
			walkingFromEndInstruction = Instruction(type: .walking, from: userLocation.coordinate, to: startStation.coordinates(), fromResult: Locations.StationResult(station: endStation), toResult: toLocation, instructionTime: 0)
		} else {
			guard let end = to as? Locations.StationResult else { fatalError() }
			endStation = end.station
		}
		
		// Determine nodes
		guard let fromNode = graph.find(node: startStation.ic) else { fatalError() }
		guard let toNode = graph.find(node: endStation.ic) else { fatalError() }
		
		// Add line status
		self.addLineStatus {
			self.isRouting = true
			
			DispatchQueue.global(qos: .userInitiated).async {
				// Calculate Routes
				self.calculateRoutes(fromNode: fromNode, toNode: toNode) { (calculatedRoutes) in
					// Generate Instructions for each calculated route
					DispatchQueue.global(qos: .userInitiated).sync {
						for (index, route) in calculatedRoutes.enumerated() {
							self.generateInstructions(from: route, finalStation: toNode.station, walkingStart: walkingToStartInstruction, walkingEnd: walkingFromEndInstruction) { (instructions) in
								let route = Route(from: fromNode.station, to: toNode.station, journeyTime: route.traversalCost, stations: (route.route.map({$0.fromNode.station}) + route.route.map({$0.toNode.station})).removeDuplicates(), instructions: instructions)
								
								print("[Routing] Route \(index + 1):")
								for instruction in instructions.filter({$0.type == .route}) {
									print("[Routing] • \(instruction.from!.name) ––> \(instruction.to!.name) (via \(instruction.line!.prettyName()) heading \(instruction.direction!))")
								}
								
								// If route is unique and satisfies filter requirements, append it uniquely to routes
								let isNotAdded = !self.routes.contains(route)
								let satisfiesFilter = route.doesSatisfyFilter(self.filters)
								print("[Routing] § Route already added? \(!isNotAdded ? "✅" : "❌")")
								print("[Routing] § Route satisfies filter? \(satisfiesFilter ? "✅" : "❌")")
								print("[Routing] § Route \(satisfiesFilter && isNotAdded ? "WILL be" : "WILL NOT be") added.")
								
								if route.doesSatisfyFilter(self.filters) {
									self.routes.uniquelyAppend(route)
									print("[Routing] * SUCCESSFULLY ADDED *")
								}
								
							}
							
							if index == calculatedRoutes.count - 1 {
								self.isRouting = false
							}
						}
						
						// Add journey to database
						Journeys.shared.addRecentJourney(journey: Journeys.Journey(from: self.from, to: self.to, date: Date()))
						
						// Send notification that routing is complete
						NotificationCenter.default.post(name: Notification.Name("routing.didComplete"), object: nil, userInfo: nil)
						
						if !self.isRouting {
							completion(self.routes)
						}
					}
				}
			}
		}
	}
	
	private func calculateRoutes(fromNode: Node, toNode: Node, completion: @escaping([Graph.Route]) -> Void) {
		NotificationCenter.default.post(name: Notification.Name("routing.startedFindingRoutes"), object: nil, userInfo: nil)
		self.findPaths(from: fromNode, to: toNode) { (routes) in
			// Send notification that route filters are applying
			NotificationCenter.default.post(name: Notification.Name("routing.applyingFilters"), object: nil, userInfo: nil)
			
			completion(routes)
		}
	}
	
	private func findPaths(from: Node, to: Node, completion: @escaping([Graph.Route]) -> Void) {
		let routeFindingDispatch = DispatchGroup()
		var count = 0
		var routes: [Graph.Route] = []
		
		routeFindingDispatch.enter()
		// Find multiple fewest changes routes
		print("[Routing] Finding fewest changes routes")
		Graph.kShortestPaths(graph: self.graph, start: from, goal: to, numberOfPaths: 10, heuristic: .fewestChanges) { (calculatedRoutes) in
			print("[Routing] Found fewest changes routes: \(calculatedRoutes.count)")
			// Send notification that routes with fewest changes have been calculated
			NotificationCenter.default.post(name: Notification.Name("routing.fewestChangesRoutesFound"), object: nil, userInfo: nil)
			
			calculatedRoutes.forEach({routes.uniquelyAppend($0)})
			
			count += 1
			routeFindingDispatch.leave()
		}
		
		routeFindingDispatch.enter()
		// Find multiple fastest routes
		print("[Routing] Finding fastest routes")
		Graph.kShortestPaths(graph: self.graph, start: from, goal: to, numberOfPaths: 10, heuristic: .fastest) { (calculatedRoutes) in
			print("[Routing] Found fastest routes: \(calculatedRoutes.count)")
			// Send notification that fastest routes have been calculated
			NotificationCenter.default.post(name: Notification.Name("routing.fastestRoutesFound"), object: nil, userInfo: nil)
			
			calculatedRoutes.forEach({routes.uniquelyAppend($0)})
			
			count += 1
			routeFindingDispatch.leave()
		}
		
		routeFindingDispatch.enter()
		print("[Routing] Finding cheapest routes")
		if self.filters.isAvoidingZoneOne || (from.station.zone != .one && to.station.zone != .one) {
			// Find multiple lowest fare routes
			Graph.kShortestPaths(graph: self.graph, start: from, goal: to, numberOfPaths: 3, heuristic: .lowestFare) { (calculatedRoutes) in
				print("[Routing] Found cheapest routes: \(calculatedRoutes.count)")
				// Send notification that routes with lowest fares have been calculated
				NotificationCenter.default.post(name: Notification.Name("routing.lowestFareRoutesFound"), object: nil, userInfo: nil)
				
				calculatedRoutes.forEach({routes.uniquelyAppend($0)})
				
				count += 1
				routeFindingDispatch.leave()
			}
		} else {
			NotificationCenter.default.post(name: Notification.Name("routing.lowestFareRoutesFound"), object: nil, userInfo: nil)
			print("[Routing] Skipping cheapest routes")
			
			count += 1
			routeFindingDispatch.leave()
		}
		
		routeFindingDispatch.notify(queue: .global(qos: .userInitiated)) {
			// When all three have been computed, call completion handler
			print("[Routing] \(count) blocks completed")
			if count >= 3 {
				completion(routes)
			}
		}
	}

	// MARK: Route Constructor
	private func extractPath(from: Path) -> [Node] {
		var stations: [Node] = []
		
		if let previousPath = from.previousPath {
			stations = self.extractPath(from: previousPath)
		} else {
			stations.append(from.node)
			return stations
		}
		
		return stations.reversed()
	}
	
	private func calculateJourneyTime(from: Path, start: Stations.Station, end: Stations.Station) -> Int {
		guard let edgeUsed = from.edgeUsed else { return 0 }
		var journeyTime = edgeUsed.connection.travelTime
		
		var path = from.previousPath

		while path != nil {
			guard let edge = path?.edgeUsed else { return journeyTime }
			journeyTime += edge.connection.travelTime

			path = path?.previousPath

			if let currentNode = path?.node, currentNode.station.ic == start.ic {
				break
			}
		}

		return journeyTime
	}
	
	// MARK: Instruction Setup
	struct InstructionSetup {
		let station: Node
		let nextStation: Node
		let connection: Edge
	}
	
	// Preprocess the instructions so we have the current station, the next station and the edge connecting the two stations.
	// This is in order to use the same edge as the pathfinding algorithm.
	private func preprocessInstructions(from route: Graph.Route) -> [InstructionSetup] {
		return route.route.map({InstructionSetup(station: $0.fromNode, nextStation: $0.toNode, connection: $0.edge)})
	}
	
	private func generateInstructions(from route: Graph.Route, finalStation: Stations.Station, walkingStart: Instruction?, walkingEnd: Instruction?, completion: ([Instruction]) -> Void) {
		// Instruction Generation Method:
		// 1. Walking directions to start station (optional)
		// 2. Platform instruction
		// 3. Route instruction
		// 4. Repeat 2 & 3 as many times as necessary
		// 5. Exit instruction
		// 6. OSI (optional)
		// 7. Repeat 2 & 3 as many times as necessary
		// 8. Exit instruction
		// 9. OSI (optional)
		
		// Preprocess instructions
		let instructionPreprocess = self.preprocessInstructions(from: route)
		
		// Now we need to iterate over the preprocessed instructions to start generating instructions.
		var instructions: [Instruction] = []
		
		// These help with understanding whether a line or direction changed
		guard var previousLine: Stations.Line = instructionPreprocess.first?.connection.connection.line else { completion([]); return }
		guard var previousDirection: Stations.Direction = instructionPreprocess.first?.connection.connection.direction else { completion([]); return }
		
		// This is to keep track of which preprocessed parts will help with the instruction generation
		var instructionHelpers: [InstructionSetup] = []
		
		for (index, preprocess) in instructionPreprocess.enumerated() {
			instructionHelpers.append(preprocess)
			
			// Unpack preprocess
			let fromStation = preprocess.station.station
			let connection = preprocess.connection.connection
			
			if index == 0 {
				// Add the first instruction which is a platform instruction to wait for the train
				let platformInstruction = Instruction(type: .platform, station: fromStation, line: connection.line, direction: connection.direction)
				instructions.append(platformInstruction)
			}
			
			// If the line or direction will change, then we need to create the route, interchange and platform instruction
			if connection.line != previousLine || connection.direction != previousDirection {
//				print("[Routing] •• Interchange at \(fromStation.name) to \(connection.line.prettyName()) Line towards \(connection.direction)")
				var stationsForInstruction = (instructionHelpers.map({$0.station.station}) + instructionHelpers.map({$0.nextStation.station})).removeDuplicates()
				stationsForInstruction = Array(stationsForInstruction[0..<stationsForInstruction.count - 1])
				let stationConnectionsForInstruction = instructionHelpers.map({$0.connection.connection})
				let timeForInstruction = instructionHelpers.reduce(0, {$0 + $1.connection.connection.travelTime})
				guard let lastStation = stationsForInstruction.last else { continue }
				
				if previousLine == .osi {
					let exitInstruction = Instruction(type: .exit, station: lastStation, line: previousLine, direction: previousDirection)
					instructions.append(exitInstruction)
					
					let routeInstruction = Instruction(type: .walking, from: nil, to: nil, fromResult: Locations.StationResult(station: stationsForInstruction.first!), toResult: Locations.StationResult(station: stationsForInstruction.last!), instructionTime: timeForInstruction)
					instructions.append(routeInstruction)
					
				} else {
					let routeInstruction = Instruction(type: previousLine == .osi ? .walking : .route, stations: stationsForInstruction, connections: stationConnectionsForInstruction, line: previousLine, direction: previousDirection, instructionTime: timeForInstruction)
					
					instructions.append(routeInstruction)
				}
				
				instructionHelpers.removeAllButLast()
				
				if connection.line != .osi {
					let platformInstruction = Instruction(type: .platform, station: fromStation, line: connection.line, direction: connection.direction)
					instructions.append(platformInstruction)
				}
			}
			
			previousLine = connection.line
			previousDirection = connection.direction
		}
		
		// We've reached the last station. Now we need to create the route and exit instruction
		let stationsForInstruction = (instructionHelpers.map({$0.station.station}) + instructionHelpers.map({$0.nextStation.station})).removeDuplicates()
		let stationConnectionsForInstruction = instructionHelpers.map({$0.connection.connection})
		let timeForInstruction = instructionHelpers.reduce(0, {$0 + $1.connection.connection.travelTime})
		guard let firstStation = stationsForInstruction.first else { return completion(instructions) }
		guard let lastStation = stationsForInstruction.last else { return completion(instructions) }
//		print("[Routing] ** Time for Instruction: \(timeForInstruction)")
		
		if previousLine == .osi {
			let exitInstruction = Instruction(type: .exit, station: firstStation, line: previousLine, direction: previousDirection)
			instructions.append(exitInstruction)
			
			let routeInstruction = Instruction(type: .walking, from: nil, to: nil, fromResult: Locations.StationResult(station: stationsForInstruction.first!), toResult: Locations.StationResult(station: stationsForInstruction.last!), instructionTime: timeForInstruction)
			instructions.append(routeInstruction)
			
		} else {
			let routeInstruction = Instruction(type: .route, stations: stationsForInstruction, connections: stationConnectionsForInstruction, line: previousLine, direction: previousDirection, instructionTime: timeForInstruction)
			instructions.append(routeInstruction)
			
			let exitInstruction = Instruction(type: .exit, station: lastStation, line: previousLine, direction: previousDirection)
			instructions.append(exitInstruction)
		}
		
		// Add walking directions if they exist
		if let walkingStart = walkingStart {
			instructions.insert(walkingStart, at: 0)
		}
		
		if let walkingEnd = walkingEnd {
			if previousLine == .osi {
				// TODO: Combine osi and walking end if next to each other
			}
			instructions.append(walkingEnd)
		}
		
		// Callback with instructions
		completion(instructions)
	}
	
	public func selectRoute(_ index: Int) {
		self.selectedRouteIndex = index
	}
	
	public func selectedRoute() -> Route? {
		if let selectedIndex = self.selectedRouteIndex {
			return self.routes[selectedIndex]
		} else {
			return nil
		}
	}
}
