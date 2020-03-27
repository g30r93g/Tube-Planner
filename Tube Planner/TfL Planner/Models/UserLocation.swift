//
//  UserLocation.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 05/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import CoreLocation
import MapKit

final class UserLocation: NSObject {

	// MARK: Shared instance
	/// The shared instance of the location
	static var current = UserLocation()

	// MARK: Properties
	var locationManager: CLLocationManager = CLLocationManager()
	/// Tracks if user has given permission to determine their device's location
	var isPermitted: Bool = false
	/// Sorts all stations by order of distance
	private(set) var nearbyStations: [Nearest] = [] {
		didSet {
			nearbyStations.sort(by: {$0.distance < $1.distance})
		}
	}
	
	// MARK: Structs
	/**
	A representation of a station and a distance to that station
	
	- Parameters:
		- station: The station the object is referring to
		- distance: The distance between the user's current location and that station
	*/
	struct Nearest {
		let station: Stations.Station
		let distance: Double
		
		init(station: Stations.Station, distance: CLLocationDistance) {
			self.station = station
			self.distance = distance
		}
	}

	// MARK: Methods
	/// Starts the location manager
	public func startLocationManager() {
		locationManager = CLLocationManager()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()
		
		if CLLocationManager.locationServicesEnabled() {
			locationManager.startUpdatingLocation()
		}
	}
	
	/// Sends a request to update the user's current location
	public func updateLocation() -> CLLocation? {
		if CLLocationManager.locationServicesEnabled() {
			locationManager.startUpdatingLocation()
			Journeys.shared.notifyFavouriteLocationsDidChange()
			
			return locationManager.location
		} else {
			return nil
		}
	}

	/**
	Calculates the distance between two location points
	
	- Parameters:
		- from: `CLLocation` of specified location
		- to: `CLLocation` of the location in question
	
	- Returns: A `Double` representing the magnitude of the distance between the two `CLLocation` points
	*/
	internal func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
		return to.distance(from: from).magnitude
	}

	/**
	Determines the nearest stations to the specified coordinates
	
	- Parameter to: The coordinates of the specified location
	- Parameter limit: Limits the number of results
	
	- Returns: An array of stations with their distance from the specified coordinate location
	*/
	internal func getNearestStations(to coordinates: CLLocationCoordinate2D, limit: Int? = nil) -> [Nearest] {
		let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
		var nearest: [Nearest] = []
		
		// Determine the distance to each station from coordinates
		for station in Stations.current.stations {
			let stationLocation = CLLocation(latitude: CLLocationDegrees(station.lat), longitude: CLLocationDegrees(station.long))
			let distance = calculateDistance(from: location, to: stationLocation)
			nearest.append(Nearest(station: station, distance: distance))
		}
		
		// Sort the stations to be in order
		nearest.sort(by: {$0.distance < $1.distance})
		
		// Apply limit filter
		if let limit = limit {
			nearest = Array(nearest[0..<limit])
		}
		
		return nearest
	}
	
	/**
	Determines the nearest stations to the user's location
	
	- Returns: An array of stations with their distance from the user's current location
	*/
	internal func getNearestStationsToUser() -> [Nearest] {
		guard let userLocation = self.updateLocation()?.coordinate else { return [] }
		self.nearbyStations = self.getNearestStations(to: userLocation)
		
		return Array(nearbyStations[0...9])
	}

}

extension UserLocation: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		self.isPermitted = status == .authorizedAlways || status == .authorizedWhenInUse
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		locationManager.stopUpdatingLocation()
		
		guard let userLocation = locations.last?.coordinate else { return }
		
		self.nearbyStations = getNearestStations(to: userLocation)
		print("[Location] Found nearby stations: \(Array(nearbyStations.map({$0.station.name})[0...9]))")
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("[Location] Error with location - \(error)")
	}
	
}
