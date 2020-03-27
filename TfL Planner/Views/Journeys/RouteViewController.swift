//
//  RouteViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 16/07/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class RouteViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak  private var backButton: RoundButton!
	@IBOutlet weak  private var timeIndicatorRing: LoadingRing!
	@IBOutlet weak  private var endRouteButton: RoundButton!
	@IBOutlet weak  private var info: RoundButton!
	@IBOutlet weak internal var tubeMap: Map!
	@IBOutlet weak  private var streetMap: StreetMap!
	@IBOutlet weak  private var platform: Platform!
	@IBOutlet weak  private var showPlatformInformation: RoundButton!
	@IBOutlet weak  private var routeInstructionsCollection: UICollectionView!
	
	// MARK: Properties
	/// The route the user is currently viewing
	var routing: Routing!
	var selectedRoute: Routing.Route!
	
	private var information: [Information] = [] { didSet { information.sort() } }
	private var currentInformationIndex = 0
	private var switchInfoTimer: Timer!
	private var switchTimerBlock: ((Timer) -> Void)!
	internal var changeRouteTimedOut = false
	
	private var currentScreen: Screen = .tubeMap
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.setupView()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.startReselectionTimer()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		self.platform.stopTimer()
	}
	
	// MARK: Structs
	class Information: Comparable {
		let type: InformationType
		let text: String
		let color: UIColor
		
		init(type: InformationType, text: String, color: UIColor) {
			self.type = type
			self.text = text
			self.color = color
		}
		
		// MARK: Equatable
		
		static func == (lhs: Information, rhs: Information) -> Bool {
			return lhs.type.rawValue == rhs.type.rawValue
		}
		
		// MARK: Comparable
		static func < (lhs: Information, rhs: Information) -> Bool {
			return lhs.type.rawValue < rhs.type.rawValue
		}
	}
	
	// MARK: Enums
	/// The information currently being displayed
	enum InformationType: Int {
		/// Journey time
		case journeyTime = 0
		
		// Number of changes in the route
		case numberOfChanges = 1
		
		// Fare for route
		case fare = 2
		
		// User has low oyster balance
		case lowBalance = 3
	}
	
	/// The subview type currently focused
	enum Screen {
		case streetMap
		case tubeMap
		case platform
	}
	
	// MARK: Methods
	/// Sets up the view
	private func setupView() {
		// Determine route selected
		self.selectedRoute = self.routing.selectedRoute()
		
		// Hide UI
		self.hideEndRoute()
		
		// Add information switching timer
		self.setupInformationSwitching()
		
		// Determine current screen
		self.hidePlatformView()
		self.hideStreetMapView()
		self.changeMap()
		
		// Setup tube map
		self.tubeMap.setupMap {
			self.tubeMap.showRoute(self.selectedRoute)
			
			if let firstPlatformInstruction = self.selectedRoute.instructions.first(where: {$0.type == .platform}), let fromStation = firstPlatformInstruction.station {
				self.tubeMap.focus(on: fromStation)
			}
		}
	}
	
	/// Starts the loading ring animation
	private func startReselectionTimer() {
		if self.changeRouteTimedOut	{
			self.backButton.setImage(UIImage(named: "Cross"), for: .normal)
			self.showEndRoute()
			return
		}
		
		UIView.animate(withDuration: 0.2, animations: {
			self.timeIndicatorRing.backgroundColor = UIColor(named: "Navigation Bar")
		}) { (_) in
			self.timeIndicatorRing.startLoading(with: 10.0) {
				self.changeRouteTimedOut = true
				UIView.animate(withDuration: 0.4, animations: {
					self.timeIndicatorRing.alpha = 0
				}) { (_) in
					UIView.transition(with: self.backButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
						self.backButton.setImage(UIImage(named: "Cross"), for: .normal)
						self.showEndRoute()
					})
				}
			}
		}
	}
	
	private func hideEndRoute() {
		self.endRouteButton.alpha = 0
		self.endRouteButton.isUserInteractionEnabled = false
	}
	
	private func showEndRoute() {
		UIView.animate(withDuration: 0.2) {
			self.endRouteButton.alpha = 1
			self.endRouteButton.isUserInteractionEnabled = true
		}
	}
	
	/// Sets up the `info` button for switching
	private func setupInformationSwitching() {
		// Add Journey Time Info
		let journeyTimeInfo = Information(type: .journeyTime, text: "Journey Time: \(self.selectedRoute.journeyTime / 60) mins", color: UIColor(named: "Accent 7") ?? .gray)
		self.information.append(journeyTimeInfo)
		
		// Add number of changes info
		var numberOfChangesInfo: Information {
			let numberOfChanges = self.selectedRoute.instructions.filter({$0.line != .osi && $0.line != nil}).map({$0.line}).removeConsecutiveDuplicates().count - 1
			
			var text: String = ""
			if numberOfChanges == 0 {
				text = "No Changes"
			} else if numberOfChanges == 1 {
				text = "1 Change"
			} else {
				text = "\(numberOfChanges) Changes"
			}
			
			return Information(type: .numberOfChanges, text: text, color: UIColor(named: "Accent 2") ?? .gray)
		}
		self.information.append(numberOfChangesInfo)
		
		// Add fare information if it exists
		var fareInfo: Information? {
			let fare = self.selectedRoute.fareEstimate
			
			if (fare == 0 && Settings().travelcard != .child5to10) || !Settings().isShowingOysterInJourneys {
				return nil
			}
			
			return Information(type: .fare, text: "Estimated Fare: £" + String(format: "%.2f", self.selectedRoute.fareEstimate), color: UIColor(named: "Accent 4") ?? .gray)
		}
		if let fareInfo = fareInfo {
			self.information.append(fareInfo)
		}
		
		// Add oyster balance warning if necessary
		if Settings().isShowingOysterInJourneys {
			Oyster.account.determineIfBalanceIsSufficient(fare: self.selectedRoute.fareEstimate) { (success, balance, isSufficient)  in
				if (balance < 0 || !isSufficient) && success {
					let insufficientBalance = Information(type: .lowBalance, text: "Please Top Up", color: UIColor(named: "Accent 6") ?? .gray)
					
					self.information.append(insufficientBalance)
				}
			}
		}
		
		_ = self.switchInformation(showing: 0)
		
		self.switchTimerBlock = { (timer) in
			let switched = self.switchInformation(showing: self.currentInformationIndex)
			
			self.currentInformationIndex = switched == -1 ? 0 : switched
			
			if switched == -1 {
				self.setInfoToStartPosition()
				timer.invalidate()
			}
		}
		
		self.restartSwitchTimer()
	}
	
	private func switchInformation(showing index: Int) -> Int {
		guard let information = self.information.retrieve(index: index) else { return -1 }
		
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.4) {
				self.info.setTitle(information.text, for: .normal)
				self.info.backgroundColor = information.color
			}
		}
		
		return index > self.information.count - 1 ? -1 : index + 1
	}
	
	private func setInfoToStartPosition() {
		self.currentInformationIndex = 0
		guard let startInformation = self.information.first else { return }
		
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.4) {
				self.info.setTitle(startInformation.text, for: .normal)
				self.info.backgroundColor = startInformation.color
			}
		}
	}
	
	private func restartSwitchTimer() {
		self.switchInfoTimer = Timer.scheduledTimer(withTimeInterval: 1.25, repeats: true, block: self.switchTimerBlock)
		self.switchInfoTimer.fire()
	}
	
	/// Changes and updates the focus and camera of the tube map, as well as presenting platform view
	private func changeMap() {
		let data = self.selectedRoute.instructions[self.routeInstructionsCollection.indexPathsForVisibleItems.first?.section ?? 0]
		
		switch data.type {
		case .walking:
			// Show map view
			self.showStreetMapView()
			self.hidePlatformView()
			
			// Find route and display
			self.streetMap.showWalkingDirections(from: data.walkingFrom!.coordinates, to: data.walkingTo!.coordinates, originName: data.walkingFrom!.displayName, destinationName: data.walkingTo!.displayName)
			
			DispatchQueue.main.async {
				self.hidePlatformView()
				
				UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
					self.showPlatformInformation.alpha = 0
					self.showPlatformInformation.isUserInteractionEnabled = false
				})
			}
		case .platform, .exit:
			// Focus map on station
			if let stationToFocus = data.station {
				self.tubeMap.focus(on: stationToFocus)
			}
			
			// Hide map view
			self.hideStreetMapView()
			
			// Show Platform View
			if data.type == .platform {
				DispatchQueue.main.async {
					self.showPlatformInformation.setTitle("Show Platform", for: .normal)
					
					UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
						self.showPlatformInformation.alpha = 1
						self.showPlatformInformation.isUserInteractionEnabled = true
					})
				}
			} else {
				self.hidePlatformView()
			}
		case .route:
			self.tubeMap.showPath(from: data)
			
			// Hide Platform View
			DispatchQueue.main.async {
				self.hidePlatformView()
				
				UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
					self.showPlatformInformation.alpha = 0
					self.showPlatformInformation.isUserInteractionEnabled = false
				}) { (_) in
					self.showPlatformInformation.setTitle("Show Platform", for: .normal)
				}
			}
		}
	}
	
	private func showPlatformView() {
		let data = self.selectedRoute.instructions[self.routeInstructionsCollection.indexPathsForVisibleItems.first?.section ?? 0]
		guard let station = data.station else { return }
		
		self.platform.updateWith(station: station, line: data.line!, heading: data.direction!)
		self.platform.startTimer() 
		
		UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
			self.platform.alpha = 1
			self.showPlatformInformation.setTitle("Return To Map", for: .normal)
		})
		
		self.currentScreen = .platform
	}
	
	private func hidePlatformView() {
		UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
			self.platform.alpha = 0
			self.showPlatformInformation.setTitle("Show Platform", for: .normal)
		})
		self.platform.stopTimer()
		
		self.currentScreen = .tubeMap
	}
	
	private func showStreetMapView() {
		UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
			self.streetMap.alpha = 1
			self.streetMap.isUserInteractionEnabled = true
		})
		
		self.currentScreen = .streetMap
	}
	
	private func hideStreetMapView() {
		UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
			self.streetMap.alpha = 0
			self.streetMap.isUserInteractionEnabled = false
		})
		
		self.currentScreen = .tubeMap
	}
	
	// MARK: Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Return Home" {
			guard let destVC = segue.destination as? JourneyViewController else { fatalError("Could not access JourneyViewController") }
			
			destVC.currentJourney = self.routing
		}
	}
	
	// MARK: IBActions
	@IBAction private func informationWasTapped(_ sender: RoundButton) {
		self.restartSwitchTimer()
	}
	
	@IBAction private func showPlatformViewTapped(_ sender: RoundButton) {
		if self.currentScreen == .platform {
			self.hidePlatformView()
		} else {
			self.showPlatformView()
		}
	}
	
	@IBAction private func completeRouteTapped(_ sender: RoundButton) {
		self.routing = nil
		self.performSegue(withIdentifier: "Return Home", sender: self)
	}
	
	@IBAction private func dismissTapped(_ sender: RoundButton) {
		self.performSegue(withIdentifier: changeRouteTimedOut ? "Return Home" : "Reselect Journey", sender: self)
	}
	
}

extension RouteViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return self.selectedRoute.instructions.count
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Route Instruction", for: indexPath) as! RoutingCell
		let data = self.selectedRoute.instructions[indexPath.section]
		
		cell.setupCell(from: data, instructionNumber: indexPath.section, numberOfInstructions: self.selectedRoute.instructions.count)
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let data = self.selectedRoute.instructions[indexPath.section]
		
		var height: CGFloat {
			switch data.type {
			case .walking:
				return 95
			case .platform:
				return 160
			case .route:
				return 185
			case .exit:
				return 160
			}
		}
		
		return CGSize(width: UIScreen.main.bounds.width - 40, height: height)
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		self.changeMap()
	}
	
}

extension RouteViewController: UIScrollViewDelegate {
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return self.tubeMap.contentView
	}
	
}
