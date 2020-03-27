//
//  Status.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 05/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

final class Status {
	
	// MARK: Shared Instance
	static let current = Status()
	
	// MARK: Properties
	private(set) var status: [LineStatus] = []
	
	/// When the last update occurred
	private(set) var lastUpdate: Date?
	
	// MARK: Networking Properties
	/// The app ID used to access TfL Open Data
	private let appID = "4c5a58a5"
	/// The app key used to access TfL Open Data
	private let appKey = "187fdfde471557eb2bd02df91f983fac"
	
	/// The data fetch task associated with the current status
	private var currentStatusSession: URLSessionTask!
	/// The data fetch task associated with tomorrow's to next week's status
	private var futureStatusSession: URLSessionTask!
	
	// MARK: Structs
	/// The aggregate line status for a line
	struct LineStatus {
		let line: Stations.Line
		var currentStatuses: [StatusSeverity] {
			return currentStatusDetails.map({$0.severity})
		}
		
		let currentStatusDetails: [StatusInformation]
		let futureStatusDetails: [StatusInformation]
	}
	
	/// The decode status for a line
	struct DecodeStatus: Decodable, Equatable, CustomStringConvertible {
		let line: Stations.Line
		var lineStatuses: [StatusInformation]
		
		enum CodingKeys: String, CodingKey {
			case line = "id"
			case lineStatuses
		}
		
		// CustomStringConvertible
		var description: String {
			return "\nLine: \(self.line.prettyName()) --- Status Information: \(self.lineStatuses)"
		}
	}
	
	/// Decoded status information
	struct StatusInformation: Decodable, Equatable, Hashable, CustomStringConvertible {
		let severity: StatusSeverity
		let information: String?
		let affectedStops: [AffectedStops]
		let validTimePeriods: [ValidPeriod]
		
		// MARK: Decodable
		enum CodingKeys: String, CodingKey {
			case severity = "statusSeverityDescription"
			case information = "reason"
			case disruption
			case validTimePeriods = "validityPeriods"
		}
		
		enum DisruptionCodingKeys: String, CodingKey {
			case affectedStops
		}
		
		init(from decoder: Decoder) throws {
			let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
			
			self.severity = try rootContainer.decode(StatusSeverity.self, forKey: .severity)
			self.information = try rootContainer.decodeIfPresent(String.self, forKey: .information)
			
			if rootContainer.contains(.validTimePeriods) {
				let decodedTimePeriods = try rootContainer.decode([ValidPeriod].self, forKey: .validTimePeriods)
				self.validTimePeriods = decodedTimePeriods.sorted(by: {$0 < $1})
			} else {
				self.validTimePeriods = []
			}
			
			// Determine affected stops
			if rootContainer.contains(.disruption) {
				let disruption = try rootContainer.nestedContainer(keyedBy: DisruptionCodingKeys.self, forKey: .disruption)
				self.affectedStops = try disruption.decode([AffectedStops].self, forKey: .affectedStops)
			} else {
				self.affectedStops = []
			}
		}
		
		// Equatable
		static func == (lhs: StatusInformation, rhs: StatusInformation) -> Bool {
			guard let leftDetail = lhs.information else { return lhs.severity == rhs.severity }
			guard let rightDetail = rhs.information else { return lhs.severity == rhs.severity }
			return leftDetail == rightDetail
		}
		
		// Hashable
		func hash(into hasher: inout Hasher) {
			hasher.combine(information ?? "")
		}
		
		// CustomStringConvertible
		var description: String {
			return "Severity: \(self.severity.rawValue) <-> Information: \(self.information ?? "No Information")"
		}
	}
	
	struct AffectedStops: Decodable {
		let station: Stations.Station?
		
		enum CodingKeys: String, CodingKey {
			case stationNaptan
		}
		
		init(from decoder: Decoder) throws {
			let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
			
			let stationNaptan = try rootContainer.decode(String.self, forKey: .stationNaptan)
			
			self.station = Stations.current.find(naptan: stationNaptan)
		}
	}
	
	struct ValidPeriod: Decodable, Comparable {
		let from: Date
		let to: Date
		
		enum CodingKeys: String, CodingKey {
			case fromDate
			case toDate
		}
		
		init(from decoder: Decoder) throws {
			let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
			
			self.from = Date(isoDate: try rootContainer.decode(String.self, forKey: .fromDate))
			self.to = Date(isoDate: try rootContainer.decode(String.self, forKey: .toDate))
		}
		
		// MARK: Comparable
		static func < (lhs: Status.ValidPeriod, rhs: Status.ValidPeriod) -> Bool {
			return lhs.from < rhs.from
		}
	}
	
	// MARK: Enums
	/// The severity of the line status
	enum StatusSeverity: String, Codable, Comparable {
		case goodService = "Good Service"
		case reducedService = "Reduced Service"
		case minorDelays = "Minor Delays"
		case severeDelays = "Severe Delays"
		case partSuspended = "Part Suspended"
		case suspended = "Suspended"
		case plannedClosure = "Planned Closure"
		case partClosure = "Part Closure"
		case specialService = "Special Service"
		case closed = "Service Closed"
		
		// MARK: Comparable
		static func < (lhs: StatusSeverity, rhs: StatusSeverity) -> Bool {
			switch lhs {
			case .goodService:
				return false
			case .reducedService:
				switch rhs {
				case .goodService:
					return true
				case .reducedService:
					return false
				case .minorDelays:
					return false
				case .severeDelays:
					return false
				case .partSuspended:
					return false
				case .suspended:
					return false
				case .plannedClosure:
					return false
				case .partClosure:
					return false
				case .specialService:
					return false
				case .closed:
					return false
				}
			case .minorDelays:
				switch rhs {
				case .goodService:
					return true
				case .reducedService:
					return true
				case .minorDelays:
					return false
				case .severeDelays:
					return false
				case .partSuspended:
					return false
				case .suspended:
					return false
				case .plannedClosure:
					return false
				case .partClosure:
					return false
				case .specialService:
					return false
				case .closed:
					return false
				}
			case .severeDelays:
				switch rhs {
				case .goodService:
					return true
				case .reducedService:
					return true
				case .minorDelays:
					return true
				case .severeDelays:
					return false
				case .partSuspended:
					return false
				case .suspended:
					return false
				case .plannedClosure:
					return false
				case .partClosure:
					return false
				case .specialService:
					return false
				case .closed:
					return false
				}
			case .partSuspended:
				switch rhs {
				case .goodService:
					return true
				case .reducedService:
					return true
				case .minorDelays:
					return true
				case .severeDelays:
					return true
				case .partSuspended:
					return false
				case .suspended:
					return false
				case .plannedClosure:
					return false
				case .partClosure:
					return false
				case .specialService:
					return false
				case .closed:
					return false
				}
			case .suspended:
				switch rhs {
				case .goodService:
					return true
				case .reducedService:
					return true
				case .minorDelays:
					return true
				case .severeDelays:
					return true
				case .partSuspended:
					return true
				case .suspended:
					return false
				case .plannedClosure:
					return false
				case .partClosure:
					return false
				case .specialService:
					return false
				case .closed:
					return false
				}
			case .plannedClosure:
				switch rhs {
				case .goodService:
					return true
				case .reducedService:
					return true
				case .minorDelays:
					return true
				case .severeDelays:
					return true
				case .partSuspended:
					return true
				case .suspended:
					return true
				case .plannedClosure:
					return false
				case .partClosure:
					return false
				case .specialService:
					return false
				case .closed:
					return false
				}
			case .partClosure:
				switch rhs {
				case .goodService:
					return true
				case .reducedService:
					return true
				case .minorDelays:
					return true
				case .severeDelays:
					return true
				case .partSuspended:
					return true
				case .suspended:
					return true
				case .plannedClosure:
					return true
				case .partClosure:
					return false
				case .specialService:
					return false
				case .closed:
					return false
				}
			case .specialService:
				switch rhs {
				case .goodService:
					return true
				case .reducedService:
					return true
				case .minorDelays:
					return true
				case .severeDelays:
					return true
				case .partSuspended:
					return true
				case .suspended:
					return true
				case .plannedClosure:
					return true
				case .partClosure:
					return true
				case .specialService:
					return false
				case .closed:
					return false
				}
			case .closed:
				return true
			}
		}
	}
	
	// MARK: Methods
	/// Updates the last update date
	internal func updateLastFetchDate() {
		self.lastUpdate = Date()
	}
	
	// Acts as public method of updating status
	public func updateStatus(completion: @escaping([LineStatus]) -> Void) {
		// Status should only update if last update is nil or if it was more than 5 mins ago when an internet connection is available
		if let lastUpdate = self.lastUpdate, lastUpdate.addingTimeInterval(60*5) > Date() || !Networking.connection.isPermitted {
			print("[Status] Using cached status")
			completion(self.status)
			return
		}
		
		// Cancel any active tasks
		if self.currentStatusSession != nil {
			self.currentStatusSession.cancel()
		}
		
		if self.futureStatusSession != nil {
			self.futureStatusSession.cancel()
		}
		
		// Perform status update
		self.performStatusUpdate(completion: { completion($0) })
	}
	
	/// Trigger an update for the status
	private func performStatusUpdate(completion: @escaping([LineStatus]) -> Void) {
		NotificationCenter.default.post(name: Notification.Name("status.started"), object: nil, userInfo: nil)
		print("[Status] Networking status: \(Networking.connection.isPermitted)")
		
		if !Networking.connection.isPermitted {
			completion(self.status)
			print("[Status] Networking is not permitted.")
			NotificationCenter.default.post(name: Notification.Name("status.finished"), object: nil, userInfo: nil)
			return
		}
		
		// Setup data variables
		var currentStatus: [DecodeStatus] = []
		var futureStatus: [DecodeStatus] = []
		
		// Setup dispatch groups
		let currentStatusGroup = DispatchGroup()
		let futureStatusGroup = DispatchGroup()
		
		currentStatusGroup.enter()
		self.getCurrentStatus { (status) in
			currentStatus = status
			
			currentStatusGroup.leave()
		}
		
		futureStatusGroup.enter()
		self.getFutureStatus { (status) in
			futureStatus = status
			
			futureStatusGroup.leave()
		}
		
		currentStatusGroup.notify(queue: .global(qos: .userInitiated)) {
			if self.futureStatusSession.state == .completed {
				// Both tasks complete, collate the data
				self.collateData(currentStatus: &currentStatus, futureStatus: &futureStatus) {
					completion(self.status)
				}
			} else {
				print("[Status] Future status is still loading...")
			}
			
			NotificationCenter.default.post(name: Notification.Name("status.currentFetched"), object: nil, userInfo: nil)
		}
		
		futureStatusGroup.notify(queue: .global(qos: .userInitiated)) {
			if self.currentStatusSession.state == .completed {
				// Both tasks complete, collate the data
				self.collateData(currentStatus: &currentStatus, futureStatus: &futureStatus) {
					completion(self.status)
					
				}
			} else {
				print("[Status] Current status is still loading...")
			}
			
			NotificationCenter.default.post(name: Notification.Name("status.futureFetched"), object: nil, userInfo: nil)
		}
	}
	
	/// Collate the data into a single status
	private func collateData(currentStatus: inout [DecodeStatus], futureStatus: inout [DecodeStatus], completion: @escaping() -> Void) {
		if !self.status.isEmpty {
			// Status already collated
			print("[Status] Status already collated!")
			completion()
			return
		}
		
		if currentStatus.isEmpty {
			print("[Status] Did not fetch current status.")
			completion()
			return
		}
		
		if futureStatus.isEmpty {
			print("[Status] Did not fetch future status.")
			completion()
			return
		}
		
		if currentStatus.count != futureStatus.count {
			print("[Status] Statuses haven't been fully obtained!")
			completion()
			return
		}
		
		// Remove duplicate statuses
		for var current in currentStatus {
			current.lineStatuses.removeDuplicateStatuses()
		}
		
		for var future in futureStatus {
			future.lineStatuses.removeDuplicateStatuses()
		}
		
		// Collate the data of both fetches
		self.status.removeAll()
		
		for (index, current) in currentStatus.enumerated() {
			let collatedStatus = LineStatus(line: current.line, currentStatusDetails: current.lineStatuses, futureStatusDetails: futureStatus[index].lineStatuses)
			self.status.append(collatedStatus)
		}
		
		// Status fully obtained
		self.updateLastFetchDate()
		self.updateStationConnections(from: self.status)
		print("[Status] Collated Statuses!")
		NotificationCenter.default.post(name: Notification.Name("status.finished"), object: nil, userInfo: nil)
		completion()
	}
	
	/// Update Station connections for use on graph
	private func updateStationConnections(from status: [LineStatus]) {
		// Reset all connections to .goodService
		Stations.current.stations.forEach({$0.connections.forEach({$0.updateStatus(to: .goodService)})})
		
		// Iterate for each line
		for lineStatus in status {
			if lineStatus.currentStatuses.count == 1 && lineStatus.currentStatuses[0] == .goodService { continue }
			
			// Iterate through each line status
			for currentDetail in lineStatus.currentStatusDetails {
				// Determine the status
				let severity = currentDetail.severity
				let line = lineStatus.line
				
				// Get the affected stations and then map to the affected edges
				let affectedStations = currentDetail.affectedStops.map({$0.station})
				
				for station in affectedStations {
					guard let station = station else { continue }
					
					// Test for a connection to all affected stations
					for otherStation in affectedStations {
						guard let otherStation = otherStation else { continue }
						
						// FIXME: Update to retrieve all connections
						let connections = station.retrieveConnections(to: otherStation, on: line)
						connections.forEach({$0.updateStatus(to: severity); print("[Status] Updating \(station.name) to \(otherStation.name) on \(line.prettyName()) from \($0.status) to \(severity)")})
					}
				}
			}
		}
		
		print("[Status] Number of connections with not good service: \(Stations.current.stations.flatMap({$0.connections}).filter({$0.status != .goodService}).count)")
	}
	
	/// Prettify the status information by removing leading and trailing spaces as well as grammar formatting and unnatural language.
	// TODO: Use Natural Language processor to interpret the message and summarise it better
	static func prettifyStatusInformation(_ information: String) -> String {
		// Remove line name from string
		var finalString = information.substring(from: information.firstIndex(where: {$0 == ":"}) ?? information.startIndex)
		
		// Remove leading and trailing whitespaces
		finalString = finalString.trimmingCharacters(in: .punctuationCharacters).trimmingCharacters(in: .whitespaces)
		
		return finalString
	}
	
	// MARK: Network Methods
	/// Get current line status
	private func getCurrentStatus(completion: @escaping([DecodeStatus]) -> Void) {
		var currentStatus: [DecodeStatus] = []
		
		guard let currentStatusURL = URL(string: "https://api.tfl.gov.uk/Line/bakerloo,central,circle,district,hammersmith-city,jubilee,metropolitan,northern,piccadilly,victoria,waterloo-city,dlr,london-overground,tfl-rail/Status?detail=true&app_id=\(appID)&app_key=\(appKey)") else { return }
		
		let currentDispatch = DispatchGroup()
		
		currentDispatch.enter()
		DispatchQueue.global(qos: .userInitiated).async {
			self.currentStatusSession = URLSession.shared.dataTask(with: currentStatusURL, completionHandler: { (data, response, error) in
				guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { return }
				
				if let error = error {
					print(error)
					completion([])
				} else if let data = data, responseCode == 200 {
					do {
						currentStatus = try JSONDecoder().decode([DecodeStatus].self, from: data)
						
						print("[Status] Fetched Current Status")
						completion(currentStatus)
					} catch let error {
						print(error)
						completion([])
					}
				}
				
				currentDispatch.leave()
			})
			self.currentStatusSession.resume()
			
			print("[Status] Fetching Current Status...")
		}
	}
	
	/// Get future line status
	private func getFutureStatus(completion: @escaping([DecodeStatus]) -> Void) {
		var futureStatus: [DecodeStatus] = []
		
		let tomorrow = Date().tomorrow(hour: 4, minute: 30, second: 00).isoFormat()
		let nextWeek = Date().nextWeek(hour: 4, minute: 29, second: 59).isoFormat()
		guard let futureStatusURL = URL(string: "https://api.tfl.gov.uk/Line/bakerloo,central,circle,district,hammersmith-city,jubilee,metropolitan,northern,piccadilly,victoria,waterloo-city,dlr,london-overground,tfl-rail/Status/\(tomorrow)/to/\(nextWeek)?detail=true&app_id=\(appID)&app_key=\(appKey)") else { return }
		
		let futureDispatch = DispatchGroup()
		
		futureDispatch.enter()
		DispatchQueue.global(qos: .userInitiated).async {
			self.futureStatusSession = URLSession.shared.dataTask(with: futureStatusURL, completionHandler: { (data, response, error) in
				guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { futureDispatch.leave(); return }
				
				if let error = error {
					print(error)
					completion([])
				} else if let data = data, responseCode == 200 {
					do {
						futureStatus = try JSONDecoder().decode([DecodeStatus].self, from: data)
						print("[Status] Fetched Future Status")
						
						completion(futureStatus)
					} catch let error {
						print(error)
						completion([])
					}
				}
				
				futureDispatch.leave()
			})
			self.futureStatusSession.resume()
			
			print("[Status] Fetching Future Status...")
		}
	}
	
}
