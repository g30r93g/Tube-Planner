//
//  PersistenceManager.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 11/02/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import Foundation

class PersistenceManager {
	
	// MARK: Shared Instance
	static let manager = PersistenceManager()
	
	// MARK: Initialiser
	init() { }
	
	// MARK: Read Methods
	public func saveRecentJourneys(_ journeys: [Journeys.Journey]) {
		let encoder = JSONEncoder()
		do {
			let data = try encoder.encode(journeys).self
			UserDefaults.data.set(data, forKey: "RecentJourneys")
			print("[PersistenceManager] Persisted recent journeys")
		} catch let error {
			print("[PersistenceManager] Couldn't persist recent journeys - \(error.localizedDescription)")
		}
	}
	
	public func saveFavouriteLocations(_ favourites: [Journeys.FavouriteLocation]) {
		let encoder = JSONEncoder()
		do {
			let data = try encoder.encode(favourites).self
			UserDefaults.data.set(data, forKey: "FavouriteLocations")
			print("[PersistenceManager] Persisted favourite locations")
		} catch let error {
			print("[PersistenceManager] Couldn't persist favourite locations - \(error.localizedDescription)")
		}
	}
	
	// MARK: Write Methods
	public func getRecentJourneys() -> [Journeys.Journey] {
		if let data = UserDefaults.data.object(forKey: "RecentJourneys") as? Data {
			do {
				let decoder = JSONDecoder()
				return try decoder.decode([Journeys.Journey].self, from: data)
			} catch let error {
				print("[PersistenceManager] Couldn't retrieve recent journeys - \(error.localizedDescription)")
				return []
			}
		}
		
		return []
	}
	
	public func getFavouriteLocations() -> [Journeys.FavouriteLocation] {
		if let data = UserDefaults.data.object(forKey: "FavouriteLocations") as? Data {
			do {
				let decoder = JSONDecoder()
				return try decoder.decode([Journeys.FavouriteLocation].self, from: data)
			} catch let error {
				print("[PersistenceManager] Couldn't retrieve recent journeys - \(error.localizedDescription)")
				return []
			}
		}
		
		return []
	}
	
}
