//
//  Fares.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 15/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation

final class Fare {
	
	// MARK: Initialiser
	init(from: Stations.Station, to: Stations.Station, journeyStartTime: Date = Date()) {
		self.from = from
		self.to = to
		self.date = journeyStartTime
	}
	
	// MARK: Variables
	let from: Stations.Station
	let to: Stations.Station
	internal var date = Date()
	
	private var fareEstimateSession: URLSessionTask!
	/// The app ID used to access TfL Open Data
	private let appID = "4c5a58a5"
	/// The app key used to access TfL Open Data
	private let appKey = "187fdfde471557eb2bd02df91f983fac"
	
	// TODO: Account for public holidays because off peak fares are charged
	var isPeak: Bool {
		return self.isMorningPeak || self.isEveningPeak
	}
	
	/// Indicates whether the morning peak fare is being charged or not
	var isMorningPeak: Bool {
		return self.date.fallsIn(lower: date.usingTime(06, 30, 00), upper: date.usingTime(09, 30, 00)) && !Calendar(identifier: .gregorian).isWeekend
	}
	
	/// Indicates whether the evening peak fare is being charged
	/// Only charged peak fare in evening if passenger travells through zone 1
	var isEveningPeak: Bool {
		return self.date.fallsIn(lower: date.usingTime(16, 00, 00), upper: date.usingTime(19, 00, 00)) && !Calendar(identifier: .gregorian).isWeekend
	}
	
	// MARK: Enums
	/// The travelcards available
	enum Travelcards: String, Codable {
		case payg = "Adult"
		case apprentice = "Apprentice"
		case railcard = "Railcard"
		case jobcentrePlus = "JobcentrePlus"
		case student18plus = "Student 18+"
		case student16plus = "Age16To18"
		case child11to15 = "Age11To15"
		case child5to10 = "Age5To10"
	}
	
	/// The fare type
	enum FareType: String, Codable {
		case cashSingle = "CashSingle"
		case payg = "Pay as you go"
	}
	
	/// The fare time
	enum FareTime: String, Codable {
		case peak = "Peak"
		case offPeak = "Off Peak"
	}
	
	// MARK: Structs
	struct TicketRoutes: Decodable {
		let rows: [Tickets]
	}
	
	struct Tickets: Decodable {
		let passengerType: Travelcards
		let avoidsZoneOne: Bool
		let ticketsAvailable: [Fares]
		
		enum CodingKeys: String, CodingKey {
			case passengerType
			case ticketsAvailable
			case routeDescription
		}
		
		init(from decoder: Decoder) throws {
			let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
			
			self.passengerType = try rootContainer.decode(Travelcards.self, forKey: .passengerType)
			self.ticketsAvailable = try rootContainer.decode([Fares].self, forKey: .ticketsAvailable)
			
			let routeDescription = try rootContainer.decode(String.self, forKey: .routeDescription)
			self.avoidsZoneOne = routeDescription.contains("Avoiding Zone 1")
		}
	}
	
	struct Fares: Decodable {
		let cost: Double
		let type: FareType
		let time: FareTime
		
		enum CodingKeys: String, CodingKey {
			case cost
			case type = "ticketType"
			case time = "ticketTime"
		}
		
		enum NestedKeys: String, CodingKey {
			case type
		}
		
		init(from decoder: Decoder) throws {
			let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
			
			self.cost = Double(try rootContainer.decode(String.self, forKey: .cost)) ?? 0.0
			
			let typeContainer = try rootContainer.nestedContainer(keyedBy: NestedKeys.self, forKey: .type)
			self.type = FareType(rawValue: try typeContainer.decode(String.self, forKey: .type)) ?? .payg
			
			let timeContainer = try rootContainer.nestedContainer(keyedBy: NestedKeys.self, forKey: .time)
			self.time = FareTime(rawValue: try timeContainer.decode(String.self, forKey: .type)) ?? .offPeak
		}
	}
	
	struct Fare: CustomStringConvertible {
		let cost: Double
		let isPeak: Bool
		let avoidsZoneOne: Bool
		let type: FareType
		
		// MARK: CustomStringConvertible
		var description: String {
			return "\n • Fare: £\(self.cost) (\(self.type.rawValue)) - Peak Fare? \(self.isPeak ? "Yes" : "No") Must avoid zone one? \(self.avoidsZoneOne ? "Yes" : "No")"
		}
	}
	
	// MARK: Methods
	/// Performs a request to find the fare between two stations
	func findFare(fromNaptan: String, toNaptan: String, zones: [Stations.Zone], completion: @escaping(Fare?) -> Void) {
		if !Settings().isFindingFareEstimates { completion(nil); return }
		
		let passengerType = Settings().travelcard.rawValue
		
		guard let fareURL = URL(string: "https://api.tfl.gov.uk/Stoppoint/\(fromNaptan)/FareTo/\(toNaptan)?passengerType=\(passengerType)&app_id=\(appID)&app_key=\(appKey)") else { completion(nil); return }
		
		DispatchQueue.global(qos: .userInteractive).async {
			if Networking.connection.isPermitted {
				print("[Fares] Retrieving fares...")
				
				self.fareEstimateSession = URLSession.shared.dataTask(with: fareURL) { (data, response, error) in
					guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { print("[Fares] Failed response code"); completion(nil); return }
					
					if let error = error {
						print("[Fares] Error getting available fares - \(error.localizedDescription)")
					} else if let data = data, responseCode == 200 {
						do {
							let ticketRoutes = try JSONDecoder().decode([TicketRoutes].self, from: data)
							var retrievedFares: [Fare] = []
							for fare in ticketRoutes.flatMap({$0.rows}) {
								retrievedFares = fare.ticketsAvailable.map({Fare(cost: $0.cost, isPeak: $0.time == .peak, avoidsZoneOne: fare.avoidsZoneOne, type: $0.type)})
							}
							
							completion(self.relevantFare(for: retrievedFares, peakFare: self.isPeak, zones: zones))
						} catch let error {
							print("[Fares] Error parsing fares - \(error)")
							completion(nil)
						}
					}
				}
				
				self.fareEstimateSession.resume()
			} else {
				completion(nil)
			}
		}
	}
	
	/// Filter the relevant fares
	private func relevantFare(for fares: [Fare], peakFare: Bool, zones: [Stations.Zone]) -> Fare? {
		// Remove cash (Paper ticket) fares
		var relevantFares: [Fare] = fares.filter({$0.type == .payg})
		
		// Filter based on time
		relevantFares = relevantFares.filter({$0.isPeak == peakFare})
		
		if relevantFares.count == 1 {
			return relevantFares[0]
		}
		
		// Filter based on zones
		if zones.contains(.one) {
			return relevantFares.first(where: {!$0.avoidsZoneOne})
		} else {
			return relevantFares.first(where: {$0.avoidsZoneOne})
		}
	}
	
}
