//
//  GraphTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
@testable import TfL_Planner

class GraphTests: XCTestCase {
	
	var graph: Graph!
	
	override func setUp() {
		self.graph = Graph()
	}
	
	func testDidPopulate() {
		XCTAssert(graph.nodes.count == 416)
	}
	
	func testForDuplicateNodes() {
		let nodeSet = Set(graph.nodes.map({$0.station.ic}))
		
		let numberOfNodes = graph.nodes.count
		let numberOfNodesInSet = nodeSet.count
		
		XCTAssertFalse(numberOfNodes > numberOfNodesInSet)
	}
	
	func testFindingNode() {
		let matchingNode = graph.find(node: 1000139)
		
		XCTAssertNotNil(matchingNode)
		XCTAssert(matchingNode!.station.name == "London Bridge")
	}
	
	func testResetGraph() {
		graph.nodes.forEach({$0.edges.forEach({$0.deactivate()})})
		let numberOfActiveEdges = graph.nodes.flatMap({$0.edges.compactMap({$0.active})}).filter({$0}).count
		
		XCTAssert(numberOfActiveEdges == 0)
		
		graph.reset()
		
		let newNumberOfActiveEdges = graph.nodes.flatMap({$0.edges.compactMap({$0.active})}).filter({$0}).count
		
		XCTAssert(newNumberOfActiveEdges > 0)
	}
	
}

class NodeTests: XCTestCase {
	
	func testAddEdge() {
		guard let fromStation = Stations().find(station: 1000139) else { XCTFail(); return }
		let node = Node(station: fromStation)
		let edge = Edge(from: fromStation, to: 1000215, weight: 1, line: .jubilee, direction: .westbound)
		
		let numberOfEdges = node.edges.count
		node.add(connection: edge)
		let newNumberOfEdges = node.edges.count
		
		XCTAssert(newNumberOfEdges == numberOfEdges + 1)
	}
	
	func testFindConnections() {
		guard let fromStation = Stations().find(station: 1000139) else { XCTFail(); return }
		guard let toStation = Stations().find(station: 1000215) else { XCTFail(); return }
		let node = Node(station: fromStation)
		let connectedNode = Node(station: toStation)
		
		let connections = node.findConnections(to: connectedNode)
		
		XCTAssertFalse(connections.isEmpty)
		XCTAssert(connections.count == 1)
		
		guard let connection = connections.first else { XCTFail(); return }
		
		XCTAssert(connection.fromStation == fromStation && connection.toStation == toStation)
		XCTAssert(connection.weight == 105)
		XCTAssertTrue(connection.connection.isNightTube)
	}
	
	func testRemoveEdge() {
		guard let fromStation = Stations().find(station: 1000139) else { XCTFail(); return }
		guard let toStation = Stations().find(station: 1000215) else { XCTFail(); return }
		
		let node = Node(station: fromStation)
		let toNode = Node(station: toStation)
		let edge = Edge(from: fromStation, to: 1000215, weight: 1, line: .jubilee, direction: .westbound)
		
		node.add(connection: edge)
		_ = node.remove(ic: 1000215)
		
		XCTAssertTrue(node.findConnections(to: toNode).isEmpty)
	}
	
}

class EdgeTests: XCTestCase {
	
	func testActivate() {
		guard let fromStation = Stations().find(station: 1000139) else { XCTFail(); return }
		
		let edge = Edge(from: fromStation, to: 1000215, weight: 1, line: .jubilee, direction: .westbound)
		
		edge.activate()
		
		XCTAssertTrue(edge.active)
	}
	
	func testDeactivate() {
		guard let fromStation = Stations().find(station: 1000139) else { XCTFail(); return }
		
		let edge = Edge(from: fromStation, to: 1000215, weight: 1, line: .jubilee, direction: .westbound)
		
		edge.deactivate()
		
		XCTAssertFalse(edge.active)
	}
	
}
