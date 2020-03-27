//
//  Stations.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 04/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import MapKit

final class Stations {
	
	// MARK: Shared Instance
	static let current = Stations()
	
	// MARK: Variables
	var stations: [Station] = []
	
	// MARK: Initialiser
	init() {
		if !self.parse() { // Parses the station data but creates a fatalError if there are any serialisation issues
			fatalError("Please lint the station JSON file and check for any errors.")
		}
	}
	
	// MARK: Data Parser Structs
	/// Representation of a station
	class Station: Decodable, Equatable, Hashable {
		// MARK: Properties
		let name: String
		let ic: Int
		let naptan: [String]
		let zone: Zone
		
		let lines: [Line]
		var connections: [Connection]
		let doors: [Doors]
		let outOfStationInterchanges: [Connection]
		
		let lat: Double
		let long: Double
		
		let mapX: Double
		let mapY: Double
		
		// MARK: Methods
		/// Determines if a connection to another station on a line and returns it
		/// - parameter to: The station of interest
		/// - parameter line: The line by which the two stations are supposedly connected by
		/// - returns: A `Connection` if it exists or `nil` if no connection exists
		func retrieveConnection(to: Station, on line: Line, with direction: Direction?) -> Connection? {
			if let direction = direction {
				return self.connections.first(where: {$0.to == to.ic && $0.line == line && $0.direction == direction})
			} else {
				return self.connections.first(where: {$0.to == to.ic && $0.line == line})
			}
		}
		
		/// Returns all connections to another station on a specified line
		func retrieveConnections(to station: Station, on line: Line) -> [Connection] {
			return self.connections.filter({$0.to == station.ic && $0.line == line})
		}
		
		func retrieveOSI(to station: Station) -> Connection? {
			return self.outOfStationInterchanges.first(where: {$0.to == station.ic})
		}
		
		/// Returns a `CLLocationCoordinate2D` coordinate value based on the latitude and longitude stored
		func coordinates() -> CLLocationCoordinate2D {
			return CLLocationCoordinate2D(latitude: lat, longitude: long)
		}
		
		/// Returns the door side the line is on
		func getDoorSide(line: Line, direction: Direction) -> Doors? {
			return self.doors.first(where: {$0.line == line && $0.direction == direction})
		}
		
		// MARK: Equatable
		static func == (lhs: Stations.Station, rhs: Stations.Station) -> Bool {
			return lhs.ic == rhs.ic
		}
		
		// MARK: Hashable
		func hash(into hasher: inout Hasher) {
			hasher.combine(ic)
		}
	}
	
	/// Representation of a connection between two stations
	class Connection: Decodable, Equatable {
		let line: Line
		let direction: Direction
		let to: Int
		let travelTime: Int
		let isNightTube: Bool
		var status: Status.StatusSeverity
		
		// MARK: Methods
		func updateStatus(to status: Status.StatusSeverity) {
			self.status = status
		}
		
		// MARK: Decodable
		enum CodingKeys: CodingKey {
			case line
			case direction
			case to
			case travelTime
			case nightTube
		}
		
		required init(from decoder: Decoder) throws {
			let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
			
			if rootContainer.contains(.nightTube) {
				// Decoding Connection
				self.line = try rootContainer.decode(Line.self, forKey: .line)
				self.direction = try rootContainer.decode(Direction.self, forKey: .direction)
				self.to = try rootContainer.decode(Int.self, forKey: .to)
				self.travelTime = try rootContainer.decode(Int.self, forKey: .travelTime)
				self.isNightTube = try rootContainer.decode(Bool.self, forKey: .nightTube)
			} else {
				// Decoding OSI
				self.line = .osi
				self.direction = .direction
				self.isNightTube = true
				self.to = try rootContainer.decode(Int.self, forKey: .to)
				self.travelTime = try rootContainer.decode(Int.self, forKey: .travelTime)
			}
			
			self.status = .goodService
		}
		
		// MARK: Equatable
		static func == (lhs: Connection, rhs: Connection) -> Bool {
			return lhs.line == rhs.line && lhs.direction == rhs.direction && lhs.to == rhs.to
		}
	}
	
	/// Representation of an interchange within a station
	struct Interchange: Decodable {
		let from: String
		let to: String
		let interchangeTime: Int
	}
	
	/// Information about the doors and which side they open on
	struct Doors: Decodable {
		let line: Line
		let direction: Direction
		let side: DoorSide
	}
	
	/// Representation of a platform
	struct Platform: Decodable {
		let line: Line
		let direction: Direction
		
		let side: DoorSide
		let exits: [Exit]
	}
	
	/// Representation of a platform exit
	struct Exit: Decodable {
		let nextLine: Line
		let nextDirection: Direction
		let carriage: Int
		let door: Int
	}
	
	/// The zone of the station
	enum Zone: Int, Decodable {
		// Zone 1
		case one = 1
		
		// Boundary of Zone 1 & 2
		case oneOrTwo = 12
		
		// Zone 2
		case two = 2
		
		// Boundary of Zone 2 & 3
		case twoOrThree = 23
		
		// Zone 3
		case three = 3
		
		// Boundary of Zone 3 & 4
		case threeOrFour = 34
		
		// Zone 4
		case four = 4
		
		// Boundary of Zone 4 & 5
		case fourOrFive = 45
		
		// Zone 5
		case five = 5
		
		// Boundary of Zone 5 & 6
		case fiveOrSix = 56
		
		// Zone 6
		case six = 6
		
		// Boundary of Zone 6 & 7
		case sixOrSeven = 67
		
		// Zone 7
		case seven = 7
		
		// Boundary of Zone 7 & 8
		case sevenOrEight = 78
		
		// Zone 8
		case eight = 8
		
		// Boundary of Zone 8 & 9
		case eightOrNine = 89
		
		// Zone 9
		case nine = 9
		
		// Ancillary Zone A
		case a = 100
		
		// Ancillary Zone C
		case c = 102
		
		// Ancillary Zone F
		case f = 105
	}
	
	/// The direction in which the train is heading
	enum Direction: String, Decodable {
		case northbound = "Northbound"
		case eastbound = "Eastbound"
		case southbound = "Southbound"
		case westbound = "Westbound"
		case northboundHighBarnet = "Northbound - High Barnet Branch"
		case northboundEdgware = "Northbound - Edgware Branch"
		case northboundCharingCross = "Northbound - Charing Cross Branch"
		case northboundBank = "Northbound - Bank Branch"
		case southboundHighBarnet = "Southbound - High Barnet Branch"
		case southboundEdgware = "Southbound - Edgware Branch"
		case southboundCharingCross = "Southbound - Charing Cross Branch"
		case southboundBank = "Southbound - Bank Branch"
		case clockwise = "Clockwise"
		case antiClockwise = "Anti-Clockwise"
		case heathrow = "Heathrow"
		case reading = "Reading"
		case paddington = "Paddington"
		case shenfield = "Shenfield"
		case liverpoolStreet = "Liverpool Street"
		case enfieldTown = "Enfield Town"
		case cheshunt = "Cheshunt"
		case chingford = "Chingford"
		case romford = "Romford"
		case upminster = "Upminster"
		case barking = "Barking"
		case gospelOak = "Gospel Oak"
		case stratford = "Stratford"
		case highburyIslington = "Highbury & Islington"
		case newCross = "New Cross"
		case westCroydon = "West Croydon"
		case crystalPalace = "Crystal Palace"
		case claphamJunction = "Clapham Junction"
		case richmond = "Richmond"
		case watfordJunction = "Watford Junction"
		case euston = "Euston"
		case bank = "Bank"
		case towerGateway = "Tower Gateway"
		case lewisham = "Lewisham"
		case woolwichArsenal = "Woolwich Arsenal"
		case beckton = "Beckton"
		case stratfordInternational = "Stratford International"
		case direction = "Direction"
		
		/// Returns the canonical direction of the line
		func canonical(line: Line) -> String {
			switch line {
			case .jubilee:
				if self == .eastbound || self == .southbound {
					return "outbound"
				} else if self == .westbound || self == .northbound {
					return "inbound"
				} else {
					return ""
				}
			case .bakerloo, .victoria, .waterlooCity:
				if self == .northbound {
					return "outbound"
				} else if self == .southbound {
					return "inbound"
				} else {
					return ""
				}
			case .northern:
				if self.rawValue.contains("northbound") {
					return "outbound"
				} else if self.rawValue.contains("southbound") {
					return "inbound"
				} else {
					return ""
				}
			case .central, .piccadilly, .hammersmithCity, .metropolitan:
				if self == .eastbound {
					return "outbound"
				} else if self == .westbound {
					return "inbound"
				} else {
					return ""
				}
			case .circle:
				if self == .clockwise {
					return "outbound"
				} else if self == .antiClockwise {
					return "inbound"
				} else {
					return ""
				}
			case .district:
				if self == .eastbound {
					return "outbound"
				} else if self == .westbound {
					return "inbound"
				} else {
					return ""
				}
			case .overground, .tflRail, .dlr, .osi:
				return self.rawValue
			}
		}
	}
	
	/// The line of a tube line
	enum Line: String, Codable {
		case hammersmithCity = "hammersmith-city"
		case waterlooCity = "waterloo-city"
		case overground = "london-overground"
		case tflRail = "tfl-rail"
		case bakerloo
		case central
		case circle
		case district
		case jubilee
		case metropolitan
		case northern
		case piccadilly
		case victoria
		case dlr
		case osi
		
		/// The full name of the line
		func prettyName() -> String {
			switch self {
			case .bakerloo:
				return "Bakerloo"
			case .central:
				return "Central"
			case .circle:
				return "Circle"
			case .district:
				return "District"
			case .hammersmithCity:
				return "Hammersmith & City"
			case .jubilee:
				return "Jubilee"
			case .metropolitan:
				return "Metropolitan"
			case .northern:
				return "Northern"
			case .piccadilly:
				return "Piccadilly"
			case .victoria:
				return "Victoria"
			case .waterlooCity:
				return "Waterloo & City"
			case .dlr:
				return "DLR"
			case .overground:
				return "London Overground"
			case .tflRail:
				return "TfL Rail"
			case .osi:
				return "Walking Interchange"
			}
		}
		
		// The abbreviated name of the line
		func abbreviation() -> String {
			switch self {
			case .bakerloo:
				return "Bkr"
			case .central:
				return "Cen"
			case .circle:
				return "Circ"
			case .district:
				return "Dist"
			case .hammersmithCity:
				return "H&C"
			case .jubilee:
				return "Jub"
			case .metropolitan:
				return "Met"
			case .northern:
				return "Nrth"
			case .piccadilly:
				return "Pic"
			case .victoria:
				return "Vic"
			case .waterlooCity:
				return "W&C"
			case .dlr:
				return "DLR"
			case .overground:
				return "Ovr"
			case .tflRail:
				return "TfL"
			case .osi:
				return "Walk"
			}
		}
	}
	
	/// The side the doors will open on
	enum DoorSide: String, Decodable {
		/// Doors will open on the left hand side
		case left
		/// Doors will open on the right hand side
		case right
		/// Doors will open on both sides
		case both
		/// Doors will open on either side
		case either
		/// FatalError()
		case none
	}
	
	// MARK: Methods
	/// Parses stations.json for use by the rest of the project
	/// Returns a boolean to indicate whether the json was decoded or not
	private func parse() -> Bool {
		guard let stationJSON = Bundle.main.path(forResource: "Stations", ofType: "json") else { return false }
		guard let data = try? Data(contentsOf: URL(fileURLWithPath: stationJSON), options: []) else { return false }
		
		do {
			stations = try JSONDecoder().decode([Station].self, from: data)
			print("[Stations] Parsed Stations.json")
			
			return true
		} catch let error {
			print("[Stations] Error decoding Stations.json: \(error)")
			
			return false
		}
	}
	
	/// Finds a station based on its id
	public func find(station id: Int) -> Station? {
		return stations.first(where: {$0.ic == id})// The station may not exist or may not be available, therefore we need to treat it as an optional
	}
	
	/// Finds a station based on its naptan code
	/// - parameter searchValue: The search value for the station name 
	public func find(naptan id: String) -> Station? {
		return stations.first(where: {$0.naptan.contains(id)})
	}
	
	/// Search for stations
	/// - parameter searchValue: The search value for the station name
	public func search(_ searchValue: String) -> [Stations.Station] {
		// Removes punctuation from station name
		return self.stations.filter({$0.name.trimmingCharacters(in: .punctuationCharacters).contains(searchValue)})
	}
	
}
