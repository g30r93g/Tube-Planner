//
//  Graph.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 05/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation

// MARK: Graph
/// A directed, weighted, graph abstract data type
final class Graph {
	
	// MARK: Initialisers
	init() {
		self.populate()
	}
	
	// MARK: Variables
	private(set) var nodes: [Node] = []
	
	// MARK: Methods
	/// Populates the graph with nodes
	internal func populate() {
		for station in Stations.current.stations {
			self.nodes.append(Node(station: station))
		}
	}
	
	/// Adds a node to the graph
	public func add(node: Node) -> [Node] {
		self.nodes.append(node)
		return self.nodes
	}
	
	/// Returns the first matching node
	/// If no node found, nil is returned
	public func find(node identifier: Int) -> Node? {
		return nodes.first(where: {$0.station.ic == identifier})
	}
	
	/// Resets the graph for reuse
	internal func reset() {
		// Update adjacency list
		for node in nodes {
			for edge in node.edges {
				// Reset to default values
				edge.visited = false
				edge.activate()
				edge.weight = Double(edge.connection.travelTime)
				
//				if Settings().hidingRoutesWithPoorStatus
				// Significantly increase edge cost where line status should 'prevent' traversal
				switch edge.connection.status {
				case .partSuspended, .suspended, .plannedClosure, .partClosure, .closed:
					edge.weight *= 1000
				default:
					break
				}
				
				// Increase edge cost where line status should inhibit traversal
				switch edge.connection.status {
				case .minorDelays:
					edge.weight *= 3
				case .severeDelays:
					edge.weight *= 5
				case .reducedService:
					edge.weight *= 2
				default:
					break
				}
				
				// Increase edge cost where is an OSI, to reduce likelihood of use
				if edge.connection.line == .osi {
					edge.weight *= 10
				}
				
				// Apply night tube services
				if Date().isNightTube() && !edge.connection.isNightTube {
					edge.deactivate()
				}
			}
		}
	}
	
	public func applyLineStatus(completion: @escaping() -> Void) {
		Status.current.updateStatus { (_) in
			self.reset()
			completion()
		}
	}
	
	public func applyNightTubeService(completion: @escaping() -> Void) {
		self.reset()
		completion()
	}
	
	// MARK: Routing Methods
	enum PathfindingType {
		case dijkstra
		case aStar
	}
	
	/**
	Calculates a path between two stations for a given graph
	
	- Parameters:
	- graph: The graph to traverse
	- start: The start node
	- goal: The end (goal) node
	- type: The method of pathfinding to use (Dijkstra or A-Star)
	- heurisic: The main factor affecting traversal cost
	*/
	static func pathfinding(graph: inout Graph, start: Node, goal: Node, type: PathfindingType, heuristic: Routing.Heuristic) -> Route? {
		// The final route
		var route: Path?
		
		// Keeps track of unvisited paths
		var unvisitedPaths: [Path] = [Path(startAt: start)] {
			didSet {
				unvisitedPaths.sort()
			}
		}
		// Keeps track of visited paths
		var visitedPaths: [Path] = []
		
		// Evaluate untraversed edges
		while !unvisitedPaths.isEmpty {
			// Get lowest scoring path
			let path = unvisitedPaths.remove(at: 0)
			visitedPaths.append(path)
			
			// Extract node from path
			let node = path.node
			
			// Check if goal node has been reached
			if node === goal {
				route = path
				break
			}
			
			// Evaluate all unexplored edges
			//			print("[Graph] Current Node: \(node.station.name) (\(path.totalCost))")
			//			let filter = node.edges.filter({!$0.visited && $0.active})
			//			print("[Graph] Current Edge: \(filter.map({"\($0.fromStation.name) -> \($0.toStation.name) (\($0.connection.line.prettyName()), \($0.connection.direction))"}))")
			//			print("[Graph] Unvisited Paths - \(unvisitedPaths.map({" ** \($0.node.station.name) \($0.totalCost)"})) **\n")
			
			for edge in node.edges where !edge.visited && edge.active {
				guard let toNode = graph.find(node: edge.toStation.ic) else { continue }
				guard !edge.visited && edge.active else { continue }
				
				// Determine whether interchange between lines occurred
				var interchangeOccurred: Bool {
					guard let currentLine = path.edgeUsed?.connection.line else { return false }
					guard let currentDirection = path.edgeUsed?.connection.direction else { return false }
					
					let newLine = edge.connection.line
					let newDirection = edge.connection.direction
					
					return (currentLine != newLine) || (currentDirection != newDirection)
				}
				
				// Calculate traversal cost
				var traversalCost: Double = edge.weight
				if type == .aStar {
					let heuristicCost = graph.manhattanDistance(from: toNode.station, to: goal.station)
					traversalCost += heuristicCost * 100
				}
				
				if heuristic == .fewestChanges || heuristic == .fastest {
					// If an interchange occurs, penalise
					if interchangeOccurred {
						traversalCost += 10000
					}
				} else if heuristic == .lowestFare {
					// If the zone decreases, penalise
					if let currentZone = path.edgeUsed?.fromStation.zone.rawValue, currentZone > graph.find(node: edge.connection.to)!.station.zone.rawValue {
						traversalCost += 10000
					}
				}
				
				// Add path for evaluation
				let pathToAdd = Path(node: toNode, cost: traversalCost, edge: edge, previousPath: path)
				unvisitedPaths.uniquelyAppend(pathToAdd)
				
				// Set edge as traversed
				edge.visited = true
				
				// FIXME: Prevent reverse paths (if it exists) from being traversed
				for reverseEdge in toNode.findConnections(to: node) {
					reverseEdge.visited = true
				}
			}
		}
		
		if let route = route {
			return graph.constructRoute(from: route)
		} else {
			return nil
		}
	}
	
	// MARK: Yen's K Shortest Paths
	static func kShortestPaths(graph: Graph, start: Node, goal: Node, numberOfPaths: Int, heuristic: Routing.Heuristic, completion: ([Route]) -> Void) {
		// Prevent start and goal node being equal
		if start == goal { completion([]); return }
		
		var routingGraph = graph
		
		var routes: [Route] = [] {
			didSet {
				routes.sort(by: {$0.traversalCost < $1.traversalCost})
			}
		}
		var alternativeRoutes: [Route] = [] {
			didSet {
				alternativeRoutes.sort(by: {$0.traversalCost < $1.traversalCost})
			}
		}
		
		// Perform Shortest Path Algorithm
		guard let shortestPath = self.pathfinding(graph: &routingGraph, start: start, goal: goal, type: .aStar, heuristic: heuristic) else { completion([]); return }
		let stations = (shortestPath.route.map({$0.fromNode.station.name}) + shortestPath.route.map({$0.toNode.station.name})).removeDuplicates()
		print("[Graph] \(heuristic) >>> Shortest Route (Base) - \(stations)\n")
		routes.append(shortestPath)
		
		if stations.count <= 2 && start.station.lines.count == 1 { completion(routes); return }
		
		routingGraph.reset()
		
		// Iterate the number of routes
		for k in 0..<numberOfPaths {
			guard let currentRoute = routes.retrieve(index: k) else { continue }
			
			// Iterate i times for range(0, routes[k].count - 2)
			var upperLimit = currentRoute.route.count - 2
			if upperLimit < 0 { upperLimit = 0 }
			
			for i in 0...upperLimit {
				// Set spur node to ith node in route
				let spurNode = currentRoute.route[i].fromNode
				
				// Avoid evaluating stations where no interchanges occur since they will
				// produse similar results to other routes, reducing running time
				if (spurNode.station.lines.count + spurNode.station.outOfStationInterchanges.count) == 1 { continue }
				
				// Set root path equal to path from source to spur
				var rootPath = Array(currentRoute.route[0...i])
				let rootPathTraversalCost = rootPath.reduce(0, {$0 + $1.edge.weight})
				
				// Set edges in root path to infinity
				rootPath.forEach({$0.edge.deactivate()})
				
				// Set inverse edges in root path to infinity
				rootPath.forEach({$0.toNode.findConnections(to: $0.fromNode).forEach({$0.deactivate()})})
				
				// Remove last subset from root path
				rootPath.removeLast()
				
				// Set spur path equal to result of Shortest Path Algorithm from Spur to Goal
				if let spurPath = self.pathfinding(graph: &routingGraph, start: spurNode, goal: goal, type: .aStar, heuristic: heuristic) {
					// Set alternative path to root path + spur path
					let alternativeRoute = Route(route: rootPath + spurPath.route, traversalCost: Int(rootPathTraversalCost) + spurPath.traversalCost)
					
					print("[Graph] \(heuristic)        Root Route = \((rootPath.map({$0.fromNode.station.name}) + rootPath.map({$0.toNode.station.name})).removeDuplicates())")
					print("[Graph] \(heuristic)        Spur Route = \((spurPath.route.map({$0.fromNode.station.name}) + spurPath.route.map({$0.toNode.station.name})).removeDuplicates())")
					print("[Graph] \(heuristic) Alternative Route = \((alternativeRoute.route.map({$0.fromNode.station.name}) + alternativeRoute.route.map({$0.toNode.station.name})).removeDuplicates())\n\n")
					
					// Add alternative path to alternative routes
					alternativeRoutes.uniquelyAppend(alternativeRoute)
				}
				
				// Reset graph
				routingGraph.reset()
			}
			
			// Break loop if number of alternative paths = 0
			if alternativeRoutes.isEmpty { break }
			
			// Move first path in alternative paths at k to paths
			if !(k < 0 || k >= alternativeRoutes.count) {
				NotificationCenter.default.post(name: Notification.Name("graph.foundRoute"), object: nil, userInfo: nil)
				routes.append(alternativeRoutes.remove(at: k))
			}
		}
		
		print("[Graph] \(heuristic) - \(routes.count) alternative routes found.")
		completion(routes)
	}
	
	/**
	Gives the manhattan distance between the next `Station` and the goal `Station`.
	
	- Parameter from: The `Station` that the user is at.
	- Parameter to: The goal `Station`.
	*/
	func manhattanDistance(from: Stations.Station, to: Stations.Station) -> Double {
		return abs(from.long - to.long) + abs(from.lat - to.lat)
	}
	
	struct Route: Equatable {
		let route: [RouteSubset]
		let traversalCost: Int
		
		static func == (lhs: Route, rhs: Route) -> Bool {
			return lhs.route == rhs.route
		}
	}
	
	struct RouteSubset: Equatable {
		let fromNode: Node
		let toNode: Node
		let edge: Edge
		
		static func == (lhs: RouteSubset, rhs: RouteSubset) -> Bool {
			return lhs.fromNode == rhs.fromNode && lhs.toNode == rhs.toNode && lhs.edge == rhs.edge
		}
	}
	
	/// Extract route from path
	func constructRoute(from: Path) -> Route {
		var route: [RouteSubset] = []
		var traversalCost: Int = 0
		
		var path: Path? = from
		while path != nil {
			guard let currentPath = path else { break }
			guard let edge = currentPath.edgeUsed else { break }
			guard let currentStation =  self.find(node: edge.fromStation.ic) else { break }
			guard let nextStation = self.find(node: edge.toStation.ic) else { break }
			
			traversalCost += edge.connection.travelTime
			route.append(RouteSubset(fromNode: currentStation, toNode: nextStation, edge: edge))
			
			path = currentPath.previousPath
		}
		route.reverse()
		
		return Route(route: route, traversalCost: traversalCost)
	}
	
}

// MARK: Node
/// A location on the graph
final class Node {
	
	// MARK: Properties
	let station: Stations.Station
	private(set) var edges: [Edge] = []
	
	// MARK: Initialiser
	init(station: Stations.Station) {
		self.station = station
		
		self.populateEdges()
	}
	
	// MARK: Methods
	func populateEdges() {
		// Tunnel & OSI Edges
		for connection in station.connections + station.outOfStationInterchanges {
			let edge = Edge(from: station, to: connection.to, weight: Double(connection.travelTime), line: connection.line, direction: connection.direction)
			self.add(connection: edge)
		}
	}
	
	func add(connection to: Edge) {
		self.edges.append(to)
	}
	
	func remove(ic: Int) -> [Edge] {
		self.edges.removeAll(where: {$0.toStation.ic == ic})
		return self.edges
	}
	
	func findConnections(to node: Node) -> [Edge] {
		return self.edges.filter({$0.connection.to == node.station.ic})
	}
	
	// MARK: Equatable
	static func == (lhs: Node, rhs: Node) -> Bool {
		return lhs.station == rhs.station
	}
	
}

// MARK: Edge
/// A connection between two nodes
final class Edge: Equatable {
	
	// MARK: Properties
	let fromStation: Stations.Station
	let toStation: Stations.Station
	var connection: Stations.Connection
	
	var visited: Bool
	var weight: Double
	var active: Bool
	
	// MARK: Initialiser
	init(from: Stations.Station, to: Int, weight: Double, line: Stations.Line, direction: Stations.Direction) {
		guard let toStation = Stations.current.find(station: to) else { fatalError("Station must exist") }
		guard let connection = from.retrieveConnection(to: toStation, on: line, with: direction) ?? from.retrieveOSI(to: toStation) else { fatalError("Connection must exist") }
		
		self.fromStation = from
		self.toStation = toStation
		self.connection = connection
		
		self.weight = weight
		self.active = true
		self.visited = false
	}
	
	// MARK: Methods
	/// Set the connection to active
	func activate() {
		self.active = true
	}
	
	/// Set the connection to inactive
	func deactivate() {
		self.active = false
	}
	
	// MARK: Equatable
	static func == (lhs: Edge, rhs: Edge) -> Bool {
		return lhs.fromStation == rhs.fromStation && lhs.toStation == rhs.toStation && lhs.connection == rhs.connection
	}
	
}

// MARK: Path
final class Path: Comparable {
	
	// MARK: Comparable
	static func < (lhs: Path, rhs: Path) -> Bool {
		return lhs.totalCost < rhs.totalCost
	}
	
	static func == (lhs: Path, rhs: Path) -> Bool {
		return lhs.node.station.ic == rhs.node.station.ic
	}
	
	// MARK: Initialisers
	init(startAt: Node) {
		self.node = startAt
		self.totalCost = 0
		self.edgeUsed = nil
		self.previousPath = nil
	}
	
	init(node: Node, cost: Double, edge: Edge, previousPath: Path) {
		self.node = node
		self.totalCost = cost + previousPath.totalCost
		self.edgeUsed = edge
		self.previousPath = previousPath
	}
	
	// MARK: Variables
	let node: Node
	let totalCost: Double
	let edgeUsed: Edge?
	let previousPath: Path?
	
}
