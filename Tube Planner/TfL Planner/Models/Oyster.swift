//
//  Oyster.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 16/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation
import UIKit

final class Oyster {
	
	// MARK: Shared Instance
	static let account = Oyster()
	
	// MARK: Initialiser
	/// Initialises a new oyster session.
	init() { }
	
	// MARK: Properties
	var oysterCards: [OysterCard] = []
	var contactlessCards: [ContactlessCard] = []
	
	private var securityToken: String = ""
	private var accessToken: String = ""
	private var refreshToken: String = ""
	
	private var osVersion: String = UIDevice.current.systemVersion
	private var modelName: String = UIDevice.current.modelName.rawValue
	
	/// When the last update occurred
	private(set) var lastUpdate: Date?
	
	// MARK: Network Properties
	private var oysterSession: URLSessionTask!
	private var contactlessSession: URLSessionTask!
	
	// Indicates whether oyster is currently fetching
	var isFetching: Bool {
		return self.oysterSession.isUpdating || self.contactlessSession.isUpdating
	}
	
	// MARK: Structs
	struct LoginResponse: Decodable {
		let responseCode: Int
		let securityToken: String
		
		private enum CodingKeys: String, CodingKey {
			case responseCode = "ResponseCode"
			case securityToken = "SecurityToken"
		}
	}
	
	struct Tokens: Decodable {
		let accessToken: String
		let refreshToken: String
		let tokenType: String
		let expiresIn: Int
		
		private enum CodingKeys: String, CodingKey {
			case accessToken = "access_token"
			case refreshToken = "refresh_token"
			case tokenType = "token_type"
			case expiresIn = "expires_in"
		}
	}
	
	// Oyster
	struct OysterDecodable: Decodable {
		let oysterCards: [OysterCard]
		
		private enum CodingKeys: String, CodingKey {
			case oysterCards = "OysterCards"
		}
	}
	
	struct OysterCard: Decodable, Equatable {
		let number: String
		let balance: Double
		let hasLowBalance: Bool
		let hasIncompleteJourney: Bool
		let lastBalanceUpdate: Date
		let hasAutoTopUp: Bool
		let autoTopUpAmount: Int
		var journeyHistory: [OysterJourney]
		
		struct CardType: Decodable {
			let name: String
			
			private enum CodingKeys: String, CodingKey {
				case name = "Name"
			}
		}
		
		private enum CodingKeys: String, CodingKey {
			case number = "OysterCardNumber"
			case balance = "Balance"
			case hasLowBalance = "IsLowBalance"
			case hasIncompleteJourney = "IsIncomplete"
			case lastBalanceUpdate = "LastBalanceTxnTime"
			case hasAutoTopUp = "AutoTopUpFlag"
			case autoTopUpAmount = "AutoTopUpAmount"
		}
		
		/// Add Journey History
		mutating func addJourneyHistory(_ journeys: [OysterJourney]) {
			self.journeyHistory = journeys
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			self.number = try container.decode(String.self, forKey: .number)
			self.balance = Double(try container.decode(Int.self, forKey: .balance)) / 100
			self.hasLowBalance = try container.decode(Bool.self, forKey: .hasLowBalance)
			self.hasIncompleteJourney = try container.decode(Bool.self, forKey: .hasIncompleteJourney)
			self.lastBalanceUpdate = Date.card(dateString: try container.decode(String.self, forKey: .lastBalanceUpdate))
			self.autoTopUpAmount = Int(try container.decode(String.self, forKey: .autoTopUpAmount)) ?? 0
			
			switch try container.decode(String.self, forKey: .hasAutoTopUp) {
			case "True":
				self.hasAutoTopUp = true
			default:
				self.hasAutoTopUp = false
			}
			
			self.journeyHistory = []
		}
		
		init(card: OysterCard, journeyHistory: [OysterJourney]) {
			self.number = card.number
			self.balance = card.balance
			self.hasLowBalance = card.hasLowBalance
			self.hasIncompleteJourney = card.hasIncompleteJourney
			self.lastBalanceUpdate = card.lastBalanceUpdate
			self.hasAutoTopUp = card.hasAutoTopUp
			self.autoTopUpAmount = card.autoTopUpAmount
			self.journeyHistory = journeyHistory.sorted(by: {$0.startTime > $1.startTime})
		}
	}
	
	struct DecodedOysterJourneyHistory: Decodable {
		let days: [DecodedOysterDays]
		
		private enum CodingKeys: String, CodingKey {
			case days = "TravelDays"
		}
	}
	
	struct DecodedOysterDays: Decodable {
		let journeys: [OysterJourney]
		
		private enum CodingKeys: String, CodingKey {
			case journeys = "Journeys"
		}
	}
	
	struct OysterJourney: Decodable, CustomStringConvertible, Hashable, Comparable {
		let startTime: Date
		let endTime: Date?
		let transactionType: TransactionType
		let fare: Double
		let from: String
		let to: String?
		let journeyStatus: JourneyStatus
		let busRoute: String?
		let capped: Bool
		let weeklyCapped: Bool
		let nightJourney: Bool
		let taps: [OysterTaps]
		
		// MARK: Decodable
		private enum CodingKeys: String, CodingKey {
			case startTime = "StartTime"
			case endTime = "EndTime"
			case transactionType = "TransactionType"
			case fare = "Charge"
			case from = "StartLocation"
			case to = "EndLocation"
			case journeyStatus = "JourneyStatus"
			case busRoute = "BusRoute"
			case capped = "Capped"
			case weeklyCapped = "WeeklyCapped"
			case nightJourney = "NightJourney"
			case taps = "Taps"
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			let start = try container.decode(String.self, forKey: .startTime)
			self.startTime = Date(isoDate: start)
			
			if let end = try container.decodeIfPresent(String.self, forKey: .endTime) {
				self.endTime = Date(isoDate: end)
			} else {
				self.endTime = nil
			}
			
			self.transactionType = TransactionType(rawValue: try container.decode(String.self, forKey: .transactionType)) ?? .unknown
			self.fare = Double(abs(try container.decode(Int.self, forKey: .fare))) / 100
			self.from = try container.decode(String.self, forKey: .from)
			if let to = try container.decodeIfPresent(String.self, forKey: .to) {
				self.to = to
			} else {
				self.to = nil
			}
			
			self.journeyStatus = JourneyStatus(rawValue: try container.decode(String.self, forKey: .journeyStatus))!
			let busRoute = try container.decodeIfPresent(String.self, forKey: .busRoute)
			if busRoute == "" {
				self.busRoute = nil
			} else {
				self.busRoute = busRoute
			}
			
			self.capped = try container.decode(Bool.self, forKey: .capped)
			self.weeklyCapped = try container.decode(Bool.self, forKey: .weeklyCapped)
			self.nightJourney = try container.decode(Bool.self, forKey: .nightJourney)
			
			self.taps = try container.decode([OysterTaps].self, forKey: .taps)
		}
		
		// MARK: CustomStringConvertible
		var description: String {
			return "\nDate: \(self.startTime) -- From: \(self.from) -- To: \(self.to ?? "nil") Fare: £\(self.fare)"
		}
		
		// MARK: Equatable
		static func == (lhs: OysterJourney, rhs: OysterJourney) -> Bool {
			return lhs.startTime == rhs.startTime && lhs.from == rhs.from && lhs.capped == rhs.capped && lhs.fare == rhs.fare && lhs.transactionType == rhs.transactionType
		}
		
		// MARK: Comparable
		static func < (lhs: OysterJourney, rhs: OysterJourney) -> Bool {
			return lhs.startTime < rhs.startTime
		}
	}
	
	struct OysterTaps: Decodable, Equatable, Hashable {
		let time: Date
		let description: String
		let validationType: OysterTapType
		
		// MARK: Decodable
		private enum CodingKeys: String, CodingKey {
			case time = "Time"
			case description = "TapTypeDescription"
			case validationType = "TapTypeId"
		}
		
		// MARK: Equatable
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			self.time = Date.journeys(dateString: try container.decode(String.self, forKey: .time))
			self.description = try container.decode(String.self, forKey: .description)
			self.validationType = OysterTapType(rawValue: try container.decode(Int.self, forKey: .validationType)) ?? .validation
		}
	}
	
	enum OysterTapType: Int {
		case entry = 79
		case exit = 84
		case topUp = 2
		case busEntry = 77
		case pinkRouteValidator = 65
		case validation = 0
		
		init?(rawValue: Self.RawValue) {
			switch rawValue {
			case 79:
				self = .entry
			case 84:
				self = .exit
			case 2:
				self = .topUp
			case 77, 22:
				self = .busEntry
			case 65:
				self = .pinkRouteValidator
			default:
				self = .validation
			}
		}
	}
	
	struct DecodedContactlessCard: Decodable, Equatable {
		let identifier: String
		let lastFourDigits: String
		let cardType: CardType
		var expiryDate: String
		
		private enum CodingKeys: String, CodingKey {
			case identifier = "Id"
			case lastFourDigits = "LastFourDigits"
			case cardType = "CardType"
			case expiryDate = "ExpiryDate"
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			self.identifier = try container.decode(String.self, forKey: .identifier)
			self.lastFourDigits = try container.decode(String.self, forKey: .lastFourDigits)
			self.cardType = CardType(rawValue: try container.decode(String.self, forKey: .cardType)) ?? .unknown
			
			let tempExpiryDate: NSMutableString = NSMutableString(string: try container.decode(String.self, forKey: .expiryDate))
			tempExpiryDate.insert("/", at: 2)
			
			self.expiryDate = String(tempExpiryDate)
		}
	}
	
	struct ContactlessCard: Hashable, Equatable {
		let identifier: String
		let lastFourDigits: String
		let cardType: CardType
		var expiryDate: String
		var journeyHistory: [ContactlessJourney]
		
		init(decodedCard: DecodedContactlessCard, journeys: [ContactlessJourney]) {
			self.identifier = decodedCard.identifier
			self.lastFourDigits = decodedCard.lastFourDigits
			self.cardType = decodedCard.cardType
			self.expiryDate = decodedCard.expiryDate
			self.journeyHistory = journeys.sorted(by: {$0.startTime > $1.startTime})
		}
	}
	
	struct DecodedContactlessJourneyHistory: Decodable {
		let days: [DecodedContactlessDays]
		
		private enum CodingKeys: String, CodingKey {
			case days = "Days"
		}
	}
	
	struct DecodedContactlessDays: Decodable {
		let journeys: [ContactlessJourney]
		
		private enum CodingKeys: String, CodingKey {
			case journeys = "Journeys"
		}
	}
	
	struct ContactlessJourney: Decodable, CustomStringConvertible, Hashable, Comparable {
		let id: String
		
		let startTime: Date
		let endTime: Date?
		let from: String
		let to: String?
		let taps: [ContactlessTaps]
		let transactionType: TransactionType
		let busRoute: String?
		
		let isNightFare: Bool
		let isHopperFare: Bool
		let wasAutoCompleted: Bool
		let baseFare: Double
		let finalFare: Double
		
		// MARK: Decodable
		private enum CodingKeys: String, CodingKey {
			case id = "JourneyId"
			case startTime = "StartTime"
			case endTime = "EndTime"
			case from = "Origin"
			case to = "Destination"
			case taps = "Taps"
			case isNightFare = "IsNightTravel"
			case isHopperFare = "IsHopperJourney"
			case wasAutoCompleted = "IsAutoCompleted"
			case baseFare = "BaseFare"
			case finalFare = "FinalFare"
			case modeType = "ModeType"
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			self.id = try container.decode(String.self, forKey: .id)
			self.startTime = Date.journeys(dateString: try container.decode(String.self, forKey: .startTime))
			if let endTime = try container.decodeIfPresent(String.self, forKey: .endTime) {
				self.endTime = Date.journeys(dateString: endTime)
			} else {
				self.endTime = nil
			}
			
			self.from = try container.decode(String.self, forKey: .from)
			if let to = try container.decodeIfPresent(String.self, forKey: .to) {
				self.to = to
			} else {
				self.to = nil
			}
			
			self.taps = try container.decode([ContactlessTaps].self, forKey: .taps)
			self.isNightFare = try container.decode(Bool.self, forKey: .isNightFare)
			self.isHopperFare = try container.decode(Bool.self, forKey: .isHopperFare)
			self.wasAutoCompleted = try container.decode(Bool.self, forKey: .wasAutoCompleted)
			self.baseFare = Double(try container.decode(Int.self, forKey: .baseFare)) / 100
			self.finalFare = Double(try container.decode(Int.self, forKey: .finalFare)) / 100
			
			let modeType = try container.decode(Int.self, forKey: .modeType)
			switch modeType {
			case 1:
				self.transactionType = .tube
			case 2:
				self.transactionType = .bus
			default:
				self.transactionType = .unknown
			}
			
			if modeType == 2 {
				self.busRoute = self.from.trimmingCharacters(in: .letters)
			} else {
				self.busRoute = nil
			}
		}
		
		// MARK: Equatable
		static func == (lhs: ContactlessJourney, rhs: ContactlessJourney) -> Bool {
			return lhs.startTime == rhs.startTime
		}
		
		// MARK: Comparable
		static func < (lhs: ContactlessJourney, rhs: ContactlessJourney) -> Bool {
			return lhs.startTime < rhs.startTime
		}
		
		// MARK: CustomStringConvertible
		var description: String {
			return "\nFrom: \(self.from) ––> To: \(self.to ?? "<NOT SET>") -- Fare: £\(self.finalFare)"
		}
	}
	
	struct ContactlessTaps: Decodable, Hashable {
		let time: Date
		let description: String
		let validationType: ValidationType
		
		private enum CodingKeys: String, CodingKey {
			case time = "Time"
			case description = "Description"
			case validationType = "ValidationTypeDescription"
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			self.time = Date.journeys(dateString: try container.decode(String.self, forKey: .time))
			self.description = try container.decode(String.self, forKey: .description)
			self.validationType = ValidationType(rawValue: try container.decode(String.self, forKey: .validationType)) ?? .validation
		}
	}
	
	// MARK: Enums
	enum CardType: String {
		case visa = "Visa"
		case mastercard = "MasterCard"
		case amex = "American Express"
		case unknown
	}
	
	enum ValidationType: String {
		case entry = "Entry"
		case exit = "Exit"
		case pinkRouteValidator = "Pink card reader"
		case validation
	}
	
	enum TransactionType: String {
		case tube = "Tube"
		case bus = "Bus"
		case rail = "Rail"
		case tflRail = "TfL Rail"
		case overground = "London Overground"
		case tram = "Tram"
		case dlr = "DLR"
		case river = "River"
		case topUp = "AddPAYG"
		case train = "OriginDest"
		case unknown = ""
	}
	
	enum JourneyStatus: String {
		case complete = "Completed"
		case incomplete = "Incomplete"
		
		init?(rawValue: Self.RawValue) {
			if rawValue == "Completed" {
				self = .complete
			} else {
				self = .incomplete
			}
		}
	}
	
	// MARK: Methods
	/// Retrieve cards and journey history
	/// - Parameter Completion: Calls back from asynchronous execution with ([OysterCard], [ContactlessCard])
	public func retrieveCards(completion: @escaping([OysterCard], [ContactlessCard]) -> Void) {
		// Status should only update if last update is nil or if it was more than 5 mins ago when an internet connection is available
		if let lastUpdate = self.lastUpdate, lastUpdate.addingTimeInterval(60*5) > Date() || !Networking.connection.isPermitted {
			print("[Oyster] Using cached oyster data")
			completion(self.oysterCards, self.contactlessCards)
			
			NotificationCenter.default.post(name: Notification.Name("oyster.finished"), object: nil, userInfo: nil)
			return
		}
		
		let username = Settings().oysterUsername
		let password = Settings().oysterPassword
		
		if username == "" || password == "" { completion(self.oysterCards, self.contactlessCards); NotificationCenter.default.post(name: Notification.Name("oyster.finished"), object: nil, userInfo: nil); return }
		
		self.login { (response) in
			guard let loginResponse = response else { completion(self.oysterCards, self.contactlessCards); NotificationCenter.default.post(name: Notification.Name("oyster.finished"), object: nil, userInfo: nil); return }
			
			self.securityToken = loginResponse.securityToken
			NotificationCenter.default.post(name: Notification.Name("oyster.fetchedSecurityToken"), object: nil, userInfo: nil)
			
			self.getAPITokens { (response) in
				guard let apiTokens = response else { completion(self.oysterCards, self.contactlessCards); NotificationCenter.default.post(name: Notification.Name("oyster.finished"), object: nil, userInfo: nil); return }
				
				self.accessToken = apiTokens.accessToken
				self.refreshToken = apiTokens.refreshToken
				NotificationCenter.default.post(name: Notification.Name("oyster.fetchedAPITokens"), object: nil, userInfo: nil)
				
				self.updateCards {
					NotificationCenter.default.post(name: Notification.Name("oyster.finished"), object: nil, userInfo: nil)
					self.lastUpdate = Date()
					completion(self.oysterCards, self.contactlessCards)
				}
			}
		}
	}
	
	/// Validate the oyster account
	public func validateOysterAccount(completion: @escaping(Bool) -> Void) {
		print("[Oyster] Validating oyster account...")
		
		self.login { (response) in
			print("[Oyster] Oyster account valid = \(response != nil)")
			completion(response != nil)
		}
	}
	
	/// Determine if the balance is enough
	/// - Parameter fare: The fare calculated for a route
	/// - Parameter completion: Calls back from asynchronous execution. `Bool` represents a success or failure `Double` represents the Oyster card's balance and `Bool` represents whether the balance is sufficient
	public func determineIfBalanceIsSufficient(fare: Double, completion: @escaping(Bool, Double, Bool) -> Void) {
		self.retrieveFavouriteOysterCard { (card) in
			guard let card = card else { completion(false, 0, false); return}
			
			completion(true, card.balance, card.balance >= fare)
		}
	}
	
	/// Retrieve the users favourite oyster card details and balance
	internal func retrieveFavouriteOysterCard(completion: @escaping(OysterCard?) -> Void) {
		self.retrieveCards { (fetchedOysterCards, _) in
			let favouriteOysterCard = Settings().favouriteCardNumber
			
			let matchingCard = fetchedOysterCards.first(where: {$0.number == favouriteOysterCard})
			completion(matchingCard)
		}
	}
	
	/// Perform update
	private func updateCards(completion: @escaping() -> Void) {
		// Setup dispatch groups
		let oysterGroup = DispatchGroup()
		let contactlessGroup = DispatchGroup()
		
		oysterGroup.enter()
		self.getOysterCards { (cards) in
			
			var fetchedOysterCards: [OysterCard] = []
			
			if cards.isEmpty {
				self.oysterCards = fetchedOysterCards
				NotificationCenter.default.post(name: Notification.Name("oyster.fetchedOysterCards"), object: nil, userInfo: nil);
				oysterGroup.leave()
			}
			
			var oysterCount = 0
			for card in cards {
				self.getOysterJourneys(for: card) { (journeyHistory) in
					fetchedOysterCards.uniquelyAppend(OysterCard(card: card, journeyHistory: journeyHistory.removeDuplicates()))
					oysterCount += 1
					
					if oysterCount == cards.count {
						self.oysterCards = fetchedOysterCards
						self.oysterCards.sort(by: {$0.journeyHistory.count > $1.journeyHistory.count})
						
						print("[Oyster] Got all journey history for oyster cards!")
						NotificationCenter.default.post(name: Notification.Name("oyster.fetchedOysterCards"), object: nil, userInfo: nil);
						oysterGroup.leave()
					}
				}
			}
		}
		
		contactlessGroup.enter()
		self.getContactlessCards { (cards) in
			var fetchedContactlessCards: [ContactlessCard] = []
			
			if cards.isEmpty {
				self.contactlessCards = fetchedContactlessCards
				NotificationCenter.default.post(name: Notification.Name("oyster.fetchedContactlessCards"), object: nil, userInfo: nil);
				contactlessGroup.leave()
			}
			
			var contactlessCount = 0
			for card in cards {
				self.getContactlessJourneys(for: card) { (journeyHistory) in
					fetchedContactlessCards.uniquelyAppend(ContactlessCard(decodedCard: card, journeys: journeyHistory.removeDuplicates()))
					contactlessCount += 1
					
					if contactlessCount == cards.count {
						self.contactlessCards = fetchedContactlessCards
						self.contactlessCards.sort(by: {$0.journeyHistory.count > $1.journeyHistory.count})
						
						print("[Oyster] Got all journey history for contactless cards!")
						NotificationCenter.default.post(name: Notification.Name("oyster.fetchedContactlessCards"), object: nil, userInfo: nil);
						contactlessGroup.leave()
					}
				}
			}
		}
		
		oysterGroup.notify(queue: .main) {
			if let contactlessSession = self.contactlessSession, contactlessSession.state == .completed {
				completion()
			} else {
				print("[Oyster] Still waiting for contactless cards...")
			}
		}
		
		contactlessGroup.notify(queue: .main) {
			if let oysterSession = self.oysterSession, oysterSession.state == .completed {
				completion()
			} else {
				print("[Oyster] Still waiting for oyster cards...")
			}
		}
	}
	
	/// Perform oyster login
	private func login(completion: @escaping(LoginResponse?) -> Void) {
		guard let url = URL(string: "https://account.tfl.gov.uk/api/login") else { completion(nil); return }
		
		let username = Settings().oysterUsername
		let password = Settings().oysterPassword
		
		let body = """
			{
			"AppId": "9C9C6B6C-A025-493E-8F39-3A6D57C7ACAB",
			"ClientId": "9C9C6B6C-A025-493E-8F39-3A6D57C7ACAB",
			"Password": "\(password)",
			"UserName": "\(username)"
			}
			"""
		guard let bodyData = body.data(using: .utf8) else { completion(nil); return }
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.httpBody = bodyData
		request.setValue("account.tfl.gov.uk", forHTTPHeaderField: ":authority")
		request.setValue("*/*", forHTTPHeaderField: "accept")
		request.setValue("0.89.3.2", forHTTPHeaderField: "appversion")
		request.setValue("IOS", forHTTPHeaderField: "platform")
		request.setValue(modelName, forHTTPHeaderField: "devicetype")
		request.setValue("en-gb", forHTTPHeaderField: "accept-language")
		request.setValue("application/json", forHTTPHeaderField: "content-type")
		request.setValue("\(body.count)", forHTTPHeaderField: "content-length")
		request.setValue("gzip, deflate, br", forHTTPHeaderField: "accept-encoding")
		request.setValue("9C9C6B6C-A025-493E-8F39-3A6D57C7ACAB", forHTTPHeaderField: "clientid")
		request.setValue("TfL%20Oyster%20and%20contactless/551 CFNetwork/1120 Darwin/19.0.0", forHTTPHeaderField: "user-agent")
		request.setValue("Basic dnNvdXNlciA6IEFaTE1URiRCdTFsZA==", forHTTPHeaderField: "authorization")
		request.setValue("__cfduid=d31e39f1b875193d3333f2ff2c57145221572964722", forHTTPHeaderField: "cookie")
		
		print("Networking status: \(Networking.connection.isPermitted)")
		if Networking.connection.isPermitted {
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { print("Response code failed"); completion(nil); return }
				
				if let error = error {
					print("[Oyster] Status: \(responseCode)")
					print("[Oyster] Error: \(error.localizedDescription)")
					completion(nil)
				} else if let data = data, responseCode == 200 {
					do {
						let decodedResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
						print("[Oyster] Fetched Login Response")
						completion(decodedResponse)
					} catch let error {
						print(error)
						completion(nil)
					}
				} else {
					print("[Oyster] Status: \(responseCode)")
					completion(nil)
				}
				
			}.resume()
		} else {
			completion(nil)
		}
	}
	
	/// Get API Tokens
	private func getAPITokens(completion: @escaping(Tokens?) -> Void) {
		guard let url = URL(string: "https://mobileapi.tfl.gov.uk/APITokens") else { return }
		var request = URLRequest(url: url)
		request.setValue("mobileapi.tfl.gov.uk", forHTTPHeaderField: ":authority")
		request.setValue("application/json", forHTTPHeaderField: "content-type")
		request.setValue(modelName, forHTTPHeaderField: "devicetype")
		request.setValue("E315443F-3344-4572-ACEF-C9C8D616A54C", forHTTPHeaderField: "deviceidentifier")
		request.setValue("*/*", forHTTPHeaderField: "accept")
		request.setValue("0.89.3.2", forHTTPHeaderField: "appversion")
		request.setValue("authorization_code", forHTTPHeaderField: "grant_type")
		request.setValue("9C9C6B6C-A025-493E-8F39-3A6D57C7ACAB", forHTTPHeaderField: "clientid")
		request.setValue("en-gb", forHTTPHeaderField: "accept-language")
		request.setValue(self.securityToken, forHTTPHeaderField: "code")
		request.setValue("IOS", forHTTPHeaderField: "platform")
		request.setValue("gzip, deflate, br", forHTTPHeaderField: "accept-encoding")
		request.setValue("TfL%20Oyster%20and%20contactless/551 CFNetwork/1120 Darwin/19.0.0", forHTTPHeaderField: "user-agent")
		request.setValue("null", forHTTPHeaderField: "notificationhandle")
		request.setValue("e45a8ca4c5014bbe8616e6fcfd53c0b8", forHTTPHeaderField: "ocp-apim-subscription-key")
		request.setValue(self.osVersion, forHTTPHeaderField: "osversion")
		request.setValue("__cfduid=d31e39f1b875193d3333f2ff2c57145221572964722", forHTTPHeaderField: "cookie")
		
		if Networking.connection.isPermitted {
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { return }
				
				if let error = error {
					print("[Oyster] Status: \(responseCode)")
					print("[Oyster] Error: \(error.localizedDescription)")
					completion(nil)
				} else if let data = data, responseCode == 200 {
					do {
						do {
							let decodedResponse = try JSONDecoder().decode(Tokens.self, from: data)
							print("[Oyster] Fetched Login Response")
							completion(decodedResponse)
						} catch let error {
							print(error)
							completion(nil)
						}
					}
				} else {
					print("[Oyster] Status: \(responseCode)")
					completion(nil)
				}
				
			}.resume()
		} else {
			completion(nil)
		}
	}
	
	/// Get oyster cards
	private func getOysterCards(completion: @escaping([OysterCard]) -> Void) {
		guard let url = URL(string: "https://mobileapi.tfl.gov.uk/Cards/Oyster") else { return }
		var request = URLRequest(url: url)
		request.setValue("mobileapi.tfl.gov.uk", forHTTPHeaderField: ":authority")
		request.setValue("application/json", forHTTPHeaderField: "content-type")
		request.setValue(modelName, forHTTPHeaderField: "devicetype")
		request.setValue("E315443F-3344-4572-ACEF-C9C8D616A54C", forHTTPHeaderField: "deviceidentifier")
		request.setValue("*/*", forHTTPHeaderField: "accept")
		request.setValue("0.89.3.2", forHTTPHeaderField: "appversion")
		request.setValue(self.accessToken, forHTTPHeaderField: "x-zumo-auth")
		request.setValue("9C9C6B6C-A025-493E-8F39-3A6D57C7ACAB", forHTTPHeaderField: "clientid")
		request.setValue("en-gb", forHTTPHeaderField: "accept-language")
		request.setValue("gzip, deflate, br", forHTTPHeaderField: "accept-encoding")
		request.setValue("IOS", forHTTPHeaderField: "platform")
		request.setValue("TfL%20Oyster%20and%20contactless/551 CFNetwork/1120 Darwin/19.0.0", forHTTPHeaderField: "user-agent")
		request.setValue("null", forHTTPHeaderField: "notificationhandle")
		request.setValue("e45a8ca4c5014bbe8616e6fcfd53c0b8", forHTTPHeaderField: "ocp-apim-subscription-key")
		request.setValue(self.osVersion, forHTTPHeaderField: "osversion")
		request.setValue("__cfduid=d31e39f1b875193d3333f2ff2c57145221572964722", forHTTPHeaderField: "cookie")
		
		if Networking.connection.isPermitted {
			self.oysterSession = URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { return }
				
				if let error = error {
					print("[Oyster] Status: \(responseCode)")
					print("[Oyster] Error: \(error.localizedDescription)")
					completion([])
				} else if let data = data, responseCode == 200 {
					do {
						do {
							let decodedResponse = try JSONDecoder().decode(OysterDecodable.self, from: data)
							print("[Oyster] Fetched Oyster Cards")
							completion(decodedResponse.oysterCards)
						} catch let error {
							print(error)
							completion([])
						}
					}
				} else {
					print("[Oyster] Status: \(responseCode)")
					completion([])
				}
				
			}
			self.oysterSession.resume()
		} else {
			completion([])
		}
	}
	
	/// Get Oyster Card's journey history
	private func getOysterJourneys(for card: OysterCard, completion: @escaping([OysterJourney]) -> Void) {
		let startDate = Date().lastWeek().tflJourneyFormat()
		let endDate = Date().tflJourneyFormat()
		guard let url = URL(string: "https://mobileapi.tfl.gov.uk/Cards/Oyster/Journeys?startDate=\(startDate)&endDate=\(endDate)") else { return }
		
		var request = URLRequest(url: url)
		request.setValue("mobileapi.tfl.gov.uk", forHTTPHeaderField: ":authority")
		request.setValue("application/json", forHTTPHeaderField: "content-type")
		request.setValue(modelName, forHTTPHeaderField: "devicetype")
		request.setValue("E315443F-3344-4572-ACEF-C9C8D616A54C", forHTTPHeaderField: "deviceidentifier")
		request.setValue("*/*", forHTTPHeaderField: "accept")
		request.setValue("0.89.3.2", forHTTPHeaderField: "appversion")
		request.setValue(self.accessToken, forHTTPHeaderField: "x-zumo-auth")
		request.setValue("9C9C6B6C-A025-493E-8F39-3A6D57C7ACAB", forHTTPHeaderField: "clientid")
		request.setValue(card.number, forHTTPHeaderField: "oystercardnumber")
		request.setValue("en-gb", forHTTPHeaderField: "accept-language")
		request.setValue("gzip, deflate, br", forHTTPHeaderField: "accept-encoding")
		request.setValue("IOS", forHTTPHeaderField: "platform")
		request.setValue("TfL%20Oyster%20and%20contactless/551 CFNetwork/1120 Darwin/19.0.0", forHTTPHeaderField: "user-agent")
		request.setValue("null", forHTTPHeaderField: "notificationhandle")
		request.setValue("e45a8ca4c5014bbe8616e6fcfd53c0b8", forHTTPHeaderField: "ocp-apim-subscription-key")
		request.setValue(self.osVersion, forHTTPHeaderField: "osversion")
		request.setValue("__cfduid=d31e39f1b875193d3333f2ff2c57145221572964722", forHTTPHeaderField: "cookie")
		
		if Networking.connection.isPermitted {
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { return }
				
				if let error = error {
					print("Status: \(responseCode)")
					print("Error: \(error.localizedDescription)")
					completion([])
				} else if let data = data, responseCode == 200 {
					do {
						do {
							let decodedResponse = try JSONDecoder().decode(DecodedOysterJourneyHistory.self, from: data)
							
							let journeys: [Oyster.OysterJourney] = decodedResponse.days.flatMap({$0.journeys}).sorted().removeConsecutiveDuplicates()
							
							print("[Oyster] Fetched journey history for oyster card \(card.number) - \(journeys)")
							
							completion(journeys)
						} catch let error {
							print(error)
							completion([])
						}
					}
				} else {
					print("[Oyster] Status: \(responseCode)")
					completion([])
				}
				
			}.resume()
		} else {
			completion([])
		}
	}
	
	/// Get contactless cards
	private func getContactlessCards(completion: @escaping([DecodedContactlessCard]) -> Void) {
		guard let url = URL(string: "https://mobileapi.tfl.gov.uk/Contactless/Cards") else { return }
		var request = URLRequest(url: url)
		request.setValue("mobileapi.tfl.gov.uk", forHTTPHeaderField: ":authority")
		request.setValue("application/json", forHTTPHeaderField: "content-type")
		request.setValue(modelName, forHTTPHeaderField: "devicetype")
		request.setValue("E315443F-3344-4572-ACEF-C9C8D616A54C", forHTTPHeaderField: "deviceidentifier")
		request.setValue("*/*", forHTTPHeaderField: "accept")
		request.setValue("0.89.3.2", forHTTPHeaderField: "appversion")
		request.setValue(self.accessToken, forHTTPHeaderField: "x-zumo-auth")
		request.setValue("9C9C6B6C-A025-493E-8F39-3A6D57C7ACAB", forHTTPHeaderField: "clientid")
		request.setValue("en-gb", forHTTPHeaderField: "accept-language")
		request.setValue("gzip, deflate, br", forHTTPHeaderField: "accept-encoding")
		request.setValue("IOS", forHTTPHeaderField: "platform")
		request.setValue("TfL%20Oyster%20and%20contactless/551 CFNetwork/1120 Darwin/19.0.0", forHTTPHeaderField: "user-agent")
		request.setValue("null", forHTTPHeaderField: "notificationhandle")
		request.setValue("e45a8ca4c5014bbe8616e6fcfd53c0b8", forHTTPHeaderField: "ocp-apim-subscription-key")
		request.setValue(self.osVersion, forHTTPHeaderField: "osversion")
		request.setValue("__cfduid=d31e39f1b875193d3333f2ff2c57145221572964722", forHTTPHeaderField: "cookie")
		
		if Networking.connection.isPermitted {
			self.contactlessSession = URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { return }
				
				if let error = error {
					print("[Oyster] Status: \(responseCode)")
					print("[Oyster] Error: \(error.localizedDescription)")
					completion([])
				} else if let data = data, responseCode == 200 {
					do {
						do {
							let decodedResponse = try JSONDecoder().decode([DecodedContactlessCard].self, from: data)
							print("[Oyster] Fetched Contactless Cards")
							completion(decodedResponse)
						} catch let error {
							print(error)
							completion([])
						}
					}
				} else {
					print("[Oyster] Status: \(responseCode)")
					completion([])
				}
				
			}
			self.contactlessSession.resume()
		} else {
			completion([])
		}
	}
	
	/// Get contactless card's journey history
	private func getContactlessJourneys(for card: DecodedContactlessCard, completion: @escaping([ContactlessJourney]) -> Void) {
		guard let url = URL(string: "https://mobileapi.tfl.gov.uk/contactless/statements/journeys") else { return }
		var request = URLRequest(url: url)
		request.setValue("mobileapi.tfl.gov.uk", forHTTPHeaderField: ":authority")
		request.setValue("E315443F-3344-4572-ACEF-C9C8D616A54C", forHTTPHeaderField: "deviceidentifier")
		request.setValue("TfL%20Oyster%20and%20contactless/551 CFNetwork/1120 Darwin/19.0.0", forHTTPHeaderField: "user-agent")
		request.setValue(Date().tflJourneyFormat(), forHTTPHeaderField: "to-date")
		request.setValue(Date().lastMonth().tflJourneyFormat(), forHTTPHeaderField: "from-date")
		request.setValue(modelName, forHTTPHeaderField: "devicetype")
		request.setValue(card.identifier, forHTTPHeaderField: "contactless-card-id")
		request.setValue("9C9C6B6C-A025-493E-8F39-3A6D57C7ACAB", forHTTPHeaderField: "clientid")
		request.setValue(self.accessToken, forHTTPHeaderField: "x-zumo-auth")
		request.setValue("e45a8ca4c5014bbe8616e6fcfd53c0b8", forHTTPHeaderField: "ocp-apim-subscription-key")
		request.setValue("0.89.3.2", forHTTPHeaderField: "appversion")
		request.setValue("IOS", forHTTPHeaderField: "platform")
		request.setValue("en-gb", forHTTPHeaderField: "accept-language")
		request.setValue("null", forHTTPHeaderField: "notificationhandle")
		request.setValue(self.osVersion, forHTTPHeaderField: "osversion")
		request.setValue("*/*", forHTTPHeaderField: "accept")
		request.setValue("application/json", forHTTPHeaderField: "content-type")
		request.setValue("gzip, deflate, br", forHTTPHeaderField: "accept-encoding")
		request.setValue("__cfduid=d31e39f1b875193d3333f2ff2c57145221572964722", forHTTPHeaderField: "cookie")
		
		if Networking.connection.isPermitted {
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				guard let responseCode = (response as? HTTPURLResponse)?.statusCode else { return }
				
				if let error = error {
					print("[Oyster] Status: \(responseCode)")
					print("[Oyster] Error: \(error.localizedDescription)")
					completion([])
				} else if let data = data, responseCode == 200 {
					do {
						do {
							let decodedResponse = try JSONDecoder().decode(DecodedContactlessJourneyHistory.self, from: data)
							
							let journeys: [Oyster.ContactlessJourney] = decodedResponse.days.flatMap({$0.journeys}).sorted().removeConsecutiveDuplicates()
							
							print("[Oyster] Fetched journey history for contactless card ending \(card.lastFourDigits) - \(journeys)")
							
							completion(journeys)
						} catch let error {
							print(error)
							completion([])
						}
					}
				} else {
					print("[Oyster] Status: \(responseCode)")
					completion([])
				}
				
			}.resume()
		} else {
			completion([])
		}
	}
	
}
