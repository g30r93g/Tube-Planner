//
//  Journeys.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 04/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import MapKit

class Journeys {
	
	// MARK: Shared Instance
	static let shared = Journeys()
	
	/// Stores recent journeys
	private(set) var journeys: [Journey] = []
	
	/// Stores favourite locations
	private(set) var favouriteLocations: [FavouriteLocation] = []
	
	// MARK: Structs
	/**
	A journey between two stations.
	
	- Parameters:
		- journeyID: The unique identifier for the journey
		- from: The origin location
		- to: The destination location
		- date: The last date this journey was performed
		- isFavourite: Whether the journey is favourited
	*/
	struct Journey: Equatable, Codable {
		let journeyID: String
		let from: Locations.LocationResult
		let to: Locations.LocationResult
		var date: Date
		
		// MARK: Initialiser
		init(journeyID: String = UUID().uuidString, from: Locations.LocationResult, to: Locations.LocationResult, date: Date) {
			self.journeyID = journeyID
			self.from = from
			self.to = to
			self.date = date
		}
	
		// MARK: Equatable
		static func == (lhs: Journeys.Journey, rhs: Journeys.Journey) -> Bool {
			return lhs.from == rhs.from && lhs.to == rhs.to
		}
		
		// MARK: Decodable
		private enum CodingKeys: String, CodingKey {
			case journeyID = "JourneyID"
			case date = "JourneyDate"
			case from = "From"
			case fromType = "FromType"
			case to = "To"
			case toType = "ToType"
		}
		
		init(from decoder: Decoder) throws {
			let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
			
			self.journeyID = try rootContainer.decode(String.self, forKey: .journeyID)
			self.date = try rootContainer.decode(Date.self, forKey: .date)
			
			let fromType = Locations.LocationResult.ResultType(rawValue: try rootContainer.decode(Int.self, forKey: .fromType))
			let toType = Locations.LocationResult.ResultType(rawValue: try rootContainer.decode(Int.self, forKey: .toType))
			
			switch fromType {
			case .station:
				self.from = try rootContainer.decode(Locations.StationResult.self, forKey: .from)
			case.poi:
				self.from = try rootContainer.decode(Locations.POIResult.self, forKey: .from)
			case .street:
				self.from = try rootContainer.decode(Locations.StreetResult.self, forKey: .from)
			default:
				fatalError()
			}
			
			switch toType {
			case .station:
				self.to = try rootContainer.decode(Locations.StationResult.self, forKey: .to)
			case .poi:
				self.to = try rootContainer.decode(Locations.POIResult.self, forKey: .to)
			case .street:
				self.to = try rootContainer.decode(Locations.StreetResult.self, forKey: .to)
			default:
				fatalError()
			}
		}
		
		// MARK: Encodable
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(journeyID, forKey: .journeyID)
			try container.encode(date, forKey: .date)
			try container.encode(from.type.rawValue, forKey: .fromType)
			try container.encode(to.type.rawValue, forKey: .toType)
			
			switch from.type {
			case .station:
				try container.encode(from as! Locations.StationResult, forKey: .from)
			case .poi:
				try container.encode(from as! Locations.POIResult, forKey: .from)
			case .street:
				try container.encode(from as! Locations.StreetResult, forKey: .from)
			}
			
			switch to.type {
			case .station:
					try container.encode(to as! Locations.StationResult, forKey: .to)
			case .poi:
					try container.encode(to as! Locations.POIResult, forKey: .to)
			case .street:
					try container.encode(to as! Locations.StreetResult, forKey: .to)
			}
		}
	}
	
	/**
	A favourite map location
	
	- Parameters:
		- favouriteID: The unique identifier for this location
		- name: The user defined name for the location
		- coordinates: The coordinate location of the favourite place
	*/
	struct FavouriteLocation: Equatable, Codable {
		let favouriteID: String
		var name: String
		
		let location: Locations.StreetResult
		
		// MARK: Initialiser
		init(favouriteID: String = UUID().uuidString, location: Locations.StreetResult) {
			self.favouriteID = favouriteID
			self.name = location.displayName
			self.location = location
		}
		
		func getNearestStation() -> Stations.Station {
			return location.nearestStation
		}
		
		func coordinates() -> CLLocationCoordinate2D {
			return location.coordinates
		}
		
		func clLocation() -> CLLocation {
			return CLLocation(latitude: location.coordinates.latitude, longitude: location.coordinates.longitude)
		}
		
		// MARK: Equatable
		static func == (lhs: Journeys.FavouriteLocation, rhs: Journeys.FavouriteLocation) -> Bool {
			return lhs.favouriteID == rhs.favouriteID
		}
		
		// MARK: Decodable
		enum CodingKeys: String, CodingKey {
			case favouriteID = "FavouriteID"
			case name = "Name"
			case location = "Location"
		}
		
		init(from decoder: Decoder) throws {
			let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
			
			self.favouriteID = try rootContainer.decode(String.self, forKey: .favouriteID)
			self.name = try rootContainer.decode(String.self, forKey: .name)
			self.location = try rootContainer.decode(Locations.StreetResult.self, forKey: .location)
		}
		
		// MARK: Encodable
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(favouriteID, forKey: .favouriteID)
			try container.encode(name, forKey: .name)
			try container.encode(location, forKey: .location)
		}
	}
	
	// MARK: Methods
	func sortFavouriteLocationsContextually() {
		guard let currentLocation = UserLocation.current.updateLocation() else { return }
		
		self.favouriteLocations.sort(by: { UserLocation.current.calculateDistance(from: currentLocation, to: $0.clLocation()) < UserLocation.current.calculateDistance(from: currentLocation, to: $1.clLocation()) })
		
		if let firstFavourite = self.favouriteLocations.first {
			if UserLocation.current.calculateDistance(from: currentLocation, to: firstFavourite.clLocation()) < 50 {
				self.favouriteLocations.move(index: 0, to: self.favouriteLocations.count - 1)
			}
		}
		
		self.notifyFavouriteLocationsDidChange()
	}
	
	// MARK: Database Load Methods
	/// Loads recent journeys from database manager
	func loadRecentJourneys() {
		self.journeys = PersistenceManager.manager.getRecentJourneys()
		self.notifyRecentJourneysDidChange()
	}
	
	/// Loads favourite locations from database manager
	func loadFavouriteLocations() {
		self.favouriteLocations = PersistenceManager.manager.getFavouriteLocations()
		self.notifyFavouriteLocationsDidChange()
		self.sortFavouriteLocationsContextually()
	}
	
	/**
	Adds a journey and persists in storage
	
	- Parameter journey: The journey to be added.
	*/
	func addRecentJourney(journey: Journey) {
		if self.journeys.contains(journey) {
			self.journeys.removeAll(where: {$0 == journey})
		}
		
		self.journeys.insert(journey, at: 0)
		PersistenceManager.manager.saveRecentJourneys(self.journeys)
		self.notifyRecentJourneysDidChange()
	}
	
	/**
	Adds a favourite location and persists in storage
	
	- Parameter location: The favourite location to be added.
	*/
	func addFavouriteLocation(location: Locations.StreetResult, withName name: String) {
		let favouriteLocation = FavouriteLocation(location: Locations.StreetResult(displayName: name, address: location.address, placemark: location.placemark))
		
		self.favouriteLocations.insert(favouriteLocation, at: 0)
		self.notifyFavouriteLocationsDidChange()
		PersistenceManager.manager.saveFavouriteLocations(self.favouriteLocations)
	}
	
	/// Removes all recent journeys
	func clearRecentJourneys() {
		self.journeys.removeAll()
		self.notifyRecentJourneysDidChange()
		PersistenceManager.manager.saveRecentJourneys(self.journeys)
	}
	
	/// Removes the favourite location with a matching favourite ID
	func removeFavouriteLocation(_ data: Journeys.FavouriteLocation) {
		self.favouriteLocations.removeAll(where: {$0 == data})
		self.notifyFavouriteLocationsDidChange()
		PersistenceManager.manager.saveFavouriteLocations(self.favouriteLocations)
	}
	
	/// Removes all favourite locations
	func removeAllFavouriteLocations() {
		self.favouriteLocations.removeAll()
		self.notifyFavouriteLocationsDidChange()
		PersistenceManager.manager.saveFavouriteLocations(self.favouriteLocations)
	}
	
	/// Notifies the application that there was an update to favourite locations
	func notifyFavouriteLocationsDidChange() {
		NotificationCenter.default.post(name: Notification.Name("favouriteLocationsDidChange"), object: nil, userInfo: nil)
	}
	
	/// Notifies the application that there was an update to recent journeys
	func notifyRecentJourneysDidChange() {
		NotificationCenter.default.post(name: Notification.Name("recentJourneysDidChange"), object: nil, userInfo: nil)
	}
	
}
