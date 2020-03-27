//
//  Settings.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 23/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

final class Settings {

	// MARK: Properties
	/// Determine if the user has completed onboarding
	var hasCompletedOnboarding: Bool {
		return UserDefaults.data.bool(forKey: "hasPerformedOnboarding")
	}
	
	/// Determines if user is wishing to save data
	var isSavingData: Bool {
		return UserDefaults.data.bool(forKey: "isSavingData")
	}
	
	/// Determines if user wishes to account for journey status
	var isShowingStatusInJourneys: Bool {
		return UserDefaults.data.bool(forKey: "statusInJourneys")
	}
	
	/// Determines if routes with poor status should be suggested
	var hidingRoutesWithPoorStatus: Bool {
		return UserDefaults.data.bool(forKey: "hideRoutesWithPoorStatus")
	}
	
	/// Determine if fare estimation is allowed
	var isFindingFareEstimates: Bool {
		return UserDefaults.data.bool(forKey: "fareEstimates")
	}
	
	/// Return the user's 'travelcard
	var travelcard: Fare.Travelcards {
		guard let travelcardString = UserDefaults.data.string(forKey: "travelcard") else { return .payg }
		guard let travelcard = Fare.Travelcards(rawValue: travelcardString) else{ return .payg }
		return travelcard
	}
	
	/// Return the user's oyster account username
	var oysterUsername: String {
		return UserDefaults.data.string(forKey: "oyster-username") ?? ""
	}
	
	/// Return the user's oyster account password
	var oysterPassword: String {
		return UserDefaults.data.string(forKey: "oyster-password") ?? ""
	}
	
	/// Return the user's favourite oyster card number
	var favouriteCardNumber: String {
		return UserDefaults.data.string(forKey: "oyster-favourite-number") ?? ""
	}
	
	/// Return the user's preferred heuristic
	var preferredRoutingSuggestion: Routing.Heuristic {
		return Routing.Heuristic(rawValue: UserDefaults.data.string(forKey: "preferredRoutingSuggestion") ?? "fastest") ?? .fastest
	}
	
	var suggestFavouriteLocations: Bool {
		return UserDefaults.data.bool(forKey: "suggestFavouriteLocations")
	}
	
	var isShowingOysterInJourneys: Bool {
		return UserDefaults.data.bool(forKey: "oysterInJourneys")
	}
	
	var routeStartStations: [Stations.Station] {
		guard let routeStartStations = UserDefaults.data.array(forKey: "routeStartStations") as? [Int] else { return [] }
		return routeStartStations.map({ Stations.current.find(station: $0)! })
	}
	
	/// The application's privacy policy
	var privacyPolicy: String {
		return """
		This privacy policy has been written to provide you (the user) with an understanding of how we use your data in this application. When you choose to opt in to services or provide personal details, we use it to provide you with features and services. We do not sell any of your personal data or any collected data. To be able to provide you with certain features, we may have to share data with third parties for the following reasons:
		• Parties involved with providing services that you’ve opted into using
		• Law enforcement where applicable
		
		Location Services:
		We use your location, with your permission, to provide contextual features, such as nearby stations, reordering your favourite locations and location triggered notifications. We do not actively track your location in the background, or report your location to any third party services. When we use your location, iOS may show an indicator in the top right corner of the status bar.
		
		Oyster Account:
		In order to provide you with information about your Oyster and Contactless cards, the Oyster Account you provide is sent to TfL's servers where you are logged in securely. We then request the information about any Oyster and Contactless cards connected with your account, balances (where possible) and a 7 day journey history. Your account details are stored securely on device and are only ever sent to TfL's servers using secure encryption methods. If you revoke access, the device erases your account details and will no longer fetch your oyster.
		
		How to contact us:
		The data controller responsible for your personal information for the purposes of the applicable European Union data protection law is:
		
		• Name: George Nick Gorzynski
		• Email: georgegorzynski@me.com
		
		If you have any queries about this Privacy Policy or how we collect your data, please feel free to contact us on the above methods.
		"""
	}
	
	// MARK: Methods
	func changeDataSaving(to: Bool) {
		UserDefaults.data.set(to, forKey: "isSavingData")
	}
	
	func changeStatusInJourneys(to: Bool) {
		UserDefaults.data.set(to, forKey: "statusInJourneys")
	}
	
	func updateHideRoutesWithPoorStatus(to: Bool) {
		UserDefaults.data.set(to, forKey: "hideRoutesWithPoorStatus")
	}
	
	func changeOysterInJourneys(to: Bool) {
		UserDefaults.data.set(to, forKey: "oysterInJourneys")
	}
	
	func changeFareEstimateRetrieval(to: Bool) {
		UserDefaults.data.set(to, forKey: "fareEstimates")
		
		if !to { self.changeOysterInJourneys(to: false) }
	}
	
	func setTravelcard(to: Fare.Travelcards) {
		UserDefaults.data.set(to.rawValue, forKey: "travelcard")
	}
	
	func userHasOnboarded() {
		UserDefaults.data.set(true, forKey: "hasPerformedOnboarding")
	}
	
	func userHasUnboarded() {
		UserDefaults.data.set(false, forKey: "hasPerformedOnboarding")
	}
	
	func changePreferredRoutingSuggestion(to: Routing.Heuristic) {
		UserDefaults.data.set(to.rawValue, forKey: "preferredRoutingSuggestion")
	}
	
	func removeOysterAccount() {
		UserDefaults.data.set("", forKey: "oyster-username")
		UserDefaults.data.set("", forKey: "oyster-password")
	}
	
	func changeOysterUsername(to username: String) {
		UserDefaults.data.set(username, forKey: "oyster-username")
	}
	
	func changeOysterPassword(to password: String) {
		UserDefaults.data.set(password, forKey: "oyster-password")
	}
	
	func updateFavouriteCard(to cardNumber: String) {
		UserDefaults.data.set(cardNumber, forKey: "oyster-favourite-number")
	}
	
	func updateSuggestingFavouriteLocations(to: Bool) {
		UserDefaults.data.set(to, forKey: "suggestFavouriteLocations")
	}
	
	func setRouteStartStations(_ stations: [Stations.Station]) {
		UserDefaults.data.set(stations.map({$0.ic}), forKey: "routeStartStations")
	}
	
	/// Restore all default values
	func reset(completion: @escaping() -> Void) {
		self.userHasUnboarded()
		
		self.removeOysterAccount()
		self.changeOysterInJourneys(to: false)
		
		self.changePreferredRoutingSuggestion(to: .fastest)
		self.setTravelcard(to: .payg)
		self.updateFavouriteCard(to: "")
		self.changeDataSaving(to: false)
		self.changeStatusInJourneys(to: true)
		self.updateHideRoutesWithPoorStatus(to: false)
		self.changeFareEstimateRetrieval(to: true)
		self.updateSuggestingFavouriteLocations(to: true)
		self.setRouteStartStations([])
		
		Journeys.shared.clearRecentJourneys()
		Journeys.shared.removeAllFavouriteLocations()
		
		completion()
	}
	
}
