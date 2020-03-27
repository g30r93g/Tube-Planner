//
//  Locations.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 25/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import MapKit

final class Locations {
	
	// MARK: Shared Instance
	static let shared = Locations()
	
	// MARK: Initialiser
	init() {
		self.pointsOfInterests = []
		
		let latitudeSpan = Stations.current.stations.max(by: {$0.lat > $1.lat})!.lat - Stations.current.stations.min(by: {$0.lat < $1.lat})!.lat
		let longitudeSpan = Stations.current.stations.max(by: {$0.long > $1.long})!.long - Stations.current.stations.min(by: {$0.long < $1.long})!.long
		let coordinateSpan = MKCoordinateSpan(latitudeDelta: latitudeSpan, longitudeDelta: longitudeSpan)
		self.london = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.501589, longitude: -0.126388), span: coordinateSpan)
		
		if !self.parsePOIs() {
			fatalError("Could not parse POIs.json. Please lint the file to check for possible failures.")
		}
	}
	
	// MARK: Properties
	private(set) var pointsOfInterests: [POI]
	
	var userLocation: POIResult? {
		if let userLocation = UserLocation.current.updateLocation()?.coordinate {
			let nearestStation = UserLocation.current.getNearestStations(to: userLocation, limit: 1).first!.station
			return POIResult(pointOfInterest: Locations.POI(displayName: "Current Location", otherNames: [], coordinate: userLocation, nearestStation: nearestStation))
		} else {
			return nil
		}
	}
	
	/// The coordinate region for Lonodn
	private let london: MKCoordinateRegion

	// MARK: Structs
	struct POI: Codable, Equatable {
		let displayName: String
		let otherNames: [String]
		let coordinate: CLLocationCoordinate2D
		let nearestStation: Stations.Station
		
		enum CodingKeys: CodingKey {
			case displayName
			case otherNames
			case latitude
			case longitude
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			self.displayName = try container.decode(String.self, forKey: .displayName)
			self.otherNames = try container.decode([String].self, forKey: .otherNames)
			
			let latitude = try container.decode(Double.self, forKey: .latitude)
			let longitude = try container.decode(Double.self, forKey: .longitude)
			self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			
			self.nearestStation	= UserLocation.current.getNearestStations(to: coordinate, limit: 1).first!.station
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(displayName, forKey: .displayName)
			try container.encode(otherNames, forKey: .otherNames)
			try container.encode(coordinate.latitude, forKey: .latitude)
			try container.encode(coordinate.longitude, forKey: .longitude)
		}
		
		init(displayName: String, otherNames: [String], coordinate: CLLocationCoordinate2D, nearestStation: Stations.Station) {
			self.displayName = displayName
			self.otherNames = otherNames
			self.coordinate = coordinate
			self.nearestStation = nearestStation
		}
		
		static func == (lhs: Locations.POI, rhs: Locations.POI) -> Bool {
			return lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude
		}
		
	}
	
	// MARK: Methods
	/// Parses POIs.json to incorporate POIs
	private func parsePOIs() -> Bool {
		guard let json = Bundle.main.path(forResource: "POIs", ofType: "json") else { return false }
		guard let data = try? Data(contentsOf: URL(fileURLWithPath: json), options: []) else { return false }
		
		do {
			self.pointsOfInterests = try JSONDecoder().decode([POI].self, from: data)
			print("[Locations] Parsed Stations.json")
			
			return true
		} catch let error {
			print("[Locations] Error decoding Stations.json: \(error)")
			
			return false
		}
	}
	
	public func findPOIs(matching searchValue: String) -> [POI] {
		return self.pointsOfInterests.filter({$0.displayName.contains(searchValue)}) + self.pointsOfInterests.filter({$0.otherNames.contains(searchValue)})
	}
	
}

extension Locations {
	
	/**
 	Returns search results based on the user's text
 	
 	- parameter searchValue: The string of text to match to locations
 	
 	- Returns: An array of locations relevant to the user's search value
 	*/
 	public func findMapLocations(matching searchValue: String, completion: @escaping([Locations.LocationResult]) -> Void) {
 		let request = MKLocalSearch.Request()
 		request.naturalLanguageQuery = searchValue
 		request.region = self.london

  		MKLocalSearch(request: request).start { (response, error) in
 			if let error = error {
 				print("Error: \(error.localizedDescription)")
 				completion([])
 			} else {
 				guard let response = response else { completion([]); return }

  				var results: [Locations.LocationResult] = []

  				for location in response.mapItems {
// 					let coordinates = location.placemark.coordinate
					
//					self.reverseGeocode(coordinates) { (address) in
						let name = location.name ?? ""
						results.append(Locations.StreetResult(displayName: name, address: "", placemark: location.placemark))
//					}
 				}

  				completion(results)
 			}
 		}
 	}
	
	/// Calculates the distance between a ```CLLocation``` and a ```CLLocationCoordinate2D```
	public func determineDistance(from: CLLocation, to: CLLocationCoordinate2D) -> CLLocationDistance {
		let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
		
		return from.distance(from: toLocation)
	}
	
}

// Search Results
extension Locations {
	
	/// A template for a location result
	class LocationResult: Equatable {
		// MARK: Initialiser
		init(type: ResultType, displayName: String, coordinates: CLLocationCoordinate2D) {
			self.type = type
			self.displayName = displayName
			self.coordinates = coordinates
		}
		
		// MARK: Properties
		let type: ResultType
		let displayName: String
		let coordinates: CLLocationCoordinate2D
		
		// MARK: Enums
		enum ResultType: Int, Codable {
			case station = 0
			case poi = 1
			case street = 2
		}
		
		// MARK: Equatable
		static func == (lhs: Locations.LocationResult, rhs: Locations.LocationResult) -> Bool {
			return lhs.coordinates.latitude == rhs.coordinates.latitude && lhs.coordinates.longitude == rhs.coordinates.longitude
		}
	}
	
	/// The class for a station search result
	final class StationResult: LocationResult, Codable {
		
		// MARK: Initialiser
		init(station: Stations.Station) {
			self.station = station
			super.init(type: .station, displayName: station.name, coordinates: station.coordinates())
		}
		
		// MARK: Properties
		let station: Stations.Station
		
		// MARK: Equatable
		static func == (lhs: Locations.StationResult, rhs: Locations.StationResult) -> Bool {
			return lhs.station == rhs.station
		}
		
		// MARK: Codable
		enum CodingKeys: String, CodingKey {
			case type
			case displayName
			case latitude
			case longitude
			case station
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			let type = try container.decode(Int.self, forKey: .type)
			let displayName = try container.decode(String.self, forKey: .displayName)
			let latitude = try container.decode(Double.self, forKey: .latitude)
			let longitude = try container.decode(Double.self, forKey: .longitude)
			let station = try container.decode(Int.self, forKey: .station)
			
			self.station = Stations.current.find(station: station)!
			super.init(type: LocationResult.ResultType(rawValue: type)!, displayName: displayName, coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(type.rawValue, forKey: .type)
			try container.encode(displayName, forKey: .displayName)
			try container.encode(coordinates.latitude, forKey: .latitude)
			try container.encode(coordinates.longitude, forKey: .longitude)
			try container.encode(station.ic, forKey: .station)
		}
	}
	
	/// The class for a Point of Interest search result
	final class POIResult: LocationResult, Codable {
		
		// MARK: Initialiser
		init(pointOfInterest: Locations.POI) {
			self.pointOfInterest = pointOfInterest
			self.nearestStation = pointOfInterest.nearestStation
			super.init(type: .poi, displayName: pointOfInterest.displayName, coordinates: pointOfInterest.coordinate)
		}
		
		// MARK: Properties
		let pointOfInterest: Locations.POI
		let nearestStation: Stations.Station
		
		// MARK: Equatable
		static func == (lhs: Locations.POIResult, rhs: Locations.POIResult) -> Bool {
			return lhs.pointOfInterest == rhs.pointOfInterest
		}
		
		// MARK: Codable
		enum CodingKeys: String, CodingKey {
			case type
			case displayName
			case latitude
			case longitude
			case pointOfInterest
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			let type = try container.decode(Int.self, forKey: .type)
			let displayName = try container.decode(String.self, forKey: .displayName)
			let latitude = try container.decode(Double.self, forKey: .latitude)
			let longitude = try container.decode(Double.self, forKey: .longitude)
			let pointOfInterest = try container.decode(Locations.POI.self, forKey: .pointOfInterest)
			
			self.pointOfInterest = pointOfInterest
			self.nearestStation = pointOfInterest.nearestStation
			super.init(type: LocationResult.ResultType(rawValue: type)!, displayName: displayName, coordinates: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(type.rawValue, forKey: .type)
			try container.encode(displayName, forKey: .displayName)
			try container.encode(coordinates.latitude, forKey: .latitude)
			try container.encode(coordinates.longitude, forKey: .longitude)
			try container.encode(pointOfInterest, forKey: .pointOfInterest)
		}
	}

	final class StreetResult: LocationResult, Codable {
		
		// MARK: Initialiser
		init(displayName: String, address: String, placemark: MKPlacemark) {
			self.address = address
			self.nearestStation	= UserLocation.current.getNearestStations(to: placemark.coordinate, limit: 1).first!.station
			self.placemark = placemark
			super.init(type: .street, displayName: displayName, coordinates: placemark.coordinate)
		}
		
		// MARK: Properties
		let nearestStation: Stations.Station
		var address: String
		let placemark: MKPlacemark
		
		// MARK: Methods
		/// Converts the coordinate into a street address
		internal func reverseGeocode(_ coordinates: CLLocationCoordinate2D, completion: @escaping(String) -> Void) {
			let geocoder = CLGeocoder()

			geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)) { (placemarks, error) in
				if let error = error {
					print("[StreetResult] Error: \(error)")
					self.address = ""
				} else if let placemark = placemarks?.first {
					self.address = "\(placemark.subThoroughfare ?? "") \(placemark.thoroughfare ?? "") \(placemark.postalCode ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
				}
			}
		}
		
		// MARK: Codable
		enum CodingKeys: String, CodingKey {
			case type
			case displayName
			case latitude
			case longitude
			case address
			case placemark
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			let type = try container.decode(Int.self, forKey: .type)
			let displayName = try container.decode(String.self, forKey: .displayName)
			let latitude = try container.decode(Double.self, forKey: .latitude)
			let longitude = try container.decode(Double.self, forKey: .longitude)
			let address = try container.decode(String.self, forKey: .address)
			let coords = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
			// TODO: Reverse geocode placemark from address, lat and long
			
			self.address = address
			self.nearestStation	= UserLocation.current.getNearestStations(to: coords, limit: 1).first!.station
			self.placemark = MKPlacemark()
			super.init(type: LocationResult.ResultType(rawValue: type)!, displayName: displayName, coordinates: coords)
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			try container.encode(type.rawValue, forKey: .type)
			try container.encode(displayName, forKey: .displayName)
			try container.encode(coordinates.latitude, forKey: .latitude)
			try container.encode(coordinates.longitude, forKey: .longitude)
			try container.encode(address, forKey: .address)
		}
	}
	
}
