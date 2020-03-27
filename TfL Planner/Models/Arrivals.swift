//
//  Arrivals.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 05/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation

final class Arrivals {
	
	// MARK: Properties
	private(set) var station: Stations.Station
	private(set) var line: Stations.Line
	private(set) var direction: Stations.Direction
	private(set) var nextArrivals: [Arrival] {
		didSet {
			self.nextArrivals = self.nextArrivals.filter({$0.timeToStation >= 0}).filter({$0.line == self.line}).filter({$0.direction.canonical(line: self.line) == self.direction.canonical(line: self.line)}).sorted()
		}
	}
	
	// MARK: Data Properties
	/// The app ID used to access TfL Open Data
	private let appID = "4c5a58a5"
	/// The app key used to access TfL Open Data
	private let appKey = "187fdfde471557eb2bd02df91f983fac"
	
	/// The data fetch task associated with the current status
	private var arrivalSession: URLSessionTask!
	
	// MARK: Initialisers
	init(station: Stations.Station, line: Stations.Line, direction: Stations.Direction) {
		self.station = station
		self.line = line
		self.direction = direction
		self.nextArrivals = []
	}
	
	// MARK: Structs
	/// The next set of arrivals for a train at a station
	final class Arrival: Decodable, Comparable {
		let line: Stations.Line
		let vehicleID: String
		var direction: Stations.Direction
		let destinationName: String
		let timeToStation: Int
		
		// MARK: Initialisers
		init(line: Stations.Line, vehicleID: String, direction: Stations.Direction, destinationName: String, timeToStation: Int) {
			self.line = line
			self.vehicleID = vehicleID
			self.direction = direction
			self.destinationName = destinationName
			self.timeToStation = timeToStation
		}
		
		init(from railArrival: RailArrival, line: Stations.Line, direction: Stations.Direction) {
			self.line = line
			self.vehicleID = ""
			self.direction = direction
			self.destinationName = railArrival.destinationName
			self.timeToStation = railArrival.timeToStation
		}
		
		// MARK: Methods
		func changeDirection(to direction: Stations.Direction) {
			self.direction = direction
		}
		
		// MARK: Decodable
		enum CodingKeys: String, CodingKey {
			case line = "lineId"
			case vehicleID = "vehicleId"
			case direction = "platformName"
			case destinationName = "towards"
			case timeToStation = "timeToStation"
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			self.line = try container.decode(Stations.Line.self, forKey: .line)
			self.vehicleID = try container.decode(String.self, forKey: .vehicleID)
			self.destinationName = try container.decode(String.self, forKey: .destinationName)
			self.timeToStation = try container.decode(Int.self, forKey: .timeToStation)
			
			let direction = try container.decode(String.self, forKey: .direction)
			guard let stationDirection = direction.split(whereSeparator: {$0 == " "}).first?.trimmingCharacters(in: .whitespacesAndNewlines) else { self.direction = .direction; return }
			self.direction = Stations.Direction(rawValue: stationDirection) ?? .direction
		}
		
		// MARK: Equatable
		static func == (lhs: Arrivals.Arrival, rhs: Arrivals.Arrival) -> Bool {
			return lhs.vehicleID == rhs.vehicleID
		}
		
		
		// MARK: Comparable
		static func < (lhs: Arrivals.Arrival, rhs: Arrivals.Arrival) -> Bool {
			return lhs.timeToStation < rhs.timeToStation
		}
	}
	
	struct RailArrival: Decodable {
		let destinationName: String
		let timeToStation: Int
		
		// MARK: Decodable
		enum CodingKeys: String, CodingKey {
			case destinationName
			case timeToStation = "minutesAndSecondsToDeparture"
		}
		
		init(from decoder: Decoder) throws {
			let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
			
			self.destinationName = try rootContainer.decode(String.self, forKey: .destinationName)
			
			let minsSecsToArrival = try rootContainer.decode(String.self, forKey: .timeToStation)
			var secondsToArrival: Int {
				guard let mins = minsSecsToArrival.split(separator: ":").map({String($0)}).retrieve(index: 0) else { return -1 }
				guard let secs = minsSecsToArrival.split(separator: ":").map({String($0)}).retrieve(index: 1) else { return -1 }
				
				guard let intMins = Int(mins) else { return -1 }
				guard let intSecs = Int(secs) else { return -1 }
				
				return (intMins * 60) + intSecs
			}
			
			self.timeToStation = secondsToArrival
		}
	}
	
	// MARK: Methods
	public func stop() {
		self.arrivalSession.cancel()
	}
	
	private func processArrivalsForSpecialCases(_ arrivals: [Arrival]) -> [Arrival] {
//		if self.line == .circle {
//			// TODO: Circle line changes half way through so I'll need a reference as to what clockwise and anti-clockwise maps to when circle changes
//		} else
		if self.line == .jubilee {
			var newArrivals = arrivals
			
			// If arrival direction doesn't match up, switch east/west bound to north/south bound
			if newArrivals.filter({$0.direction == self.direction}).isEmpty {
				newArrivals.forEach { (arrival) in
					if arrival.direction == .eastbound {
						arrival.changeDirection(to: .southbound)
						self.direction = .southbound
					} else if arrival.direction == .westbound {
						arrival.changeDirection(to: .northbound)
						self.direction = .northbound
					}
				}
			}
			
			return newArrivals
		} else {
			return arrivals
		}
	}
	
	// MARK: Network Enums
	private enum FetchType {
		case tfl
		case rail
	}
	
	// MARK: Network Methods
	/// Get arrival for a station
	public func getArrivals(completion: @escaping([Arrival]) -> Void) {
		var naptan: String {
			switch self.line {
			case .tflRail, .overground:
				return self.station.naptan.first(where: {$0.contains("910")}) ?? self.station.naptan[0]
			default:
				return self.station.naptan.first(where: {$0.contains("940")}) ?? self.station.naptan[0]
			}
		}
		
		self.fetchArrivals(for: naptan.starts(with: "940") ? .tfl : .rail, naptan: naptan) { (arrivals) in
			self.nextArrivals = self.processArrivalsForSpecialCases(arrivals)
			
			completion(self.nextArrivals)
		}
	}
	
	private func fetchArrivals(for type: FetchType, naptan: String, completion: @escaping([Arrival]) -> Void) {
		var arrivalsURL: URL? {
			switch type {
			case .tfl:
				guard let arrivalsURL = URL(string: "https://api.tfl.gov.uk/StopPoint/\(naptan)/Arrivals?app_id=\(appID)&app_key=\(appKey)") else { return nil }
				return arrivalsURL
			case .rail:
				guard let arrivalsURL = URL(string: "https://api.tfl.gov.uk/StopPoint/\(naptan)/ArrivalDepartures?lineIds=\(self.line.rawValue)&app_id=\(appID)&app_key=\(appKey)") else { return nil }
				return arrivalsURL
			}
		}
		
		guard let url = arrivalsURL else { completion([]); return }
		print("[Arrivals] Fetching arrivals at \(self.station.name) on \(self.line.prettyName()) heading \(self.direction)")
		print(url)
		
		DispatchQueue.global(qos: .userInteractive).async {
			self.arrivalSession = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
				guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { return }
				
				if let error = error {
					print(error)
					completion([])
				} else if let data = data, responseCode == 200 {
					var fetchedArrivals: [Arrival] {
						switch type {
						case .tfl:
							return try! JSONDecoder().decode([Arrival].self, from: data)
						case .rail:
							let fetchedRailArrivals = try! JSONDecoder().decode([RailArrival].self, from: data)
							return fetchedRailArrivals.map({Arrival(from: $0, line: self.line, direction: self.direction)})
						}
					}
					
					completion(fetchedArrivals)
				}
			})
			self.arrivalSession.resume()
		}
	}
	
}
