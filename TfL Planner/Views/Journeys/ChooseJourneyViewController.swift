//
//  ChooseJourneyViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 01/07/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class ChooseJourneyViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var fromStationLabel: UILabel!
	@IBOutlet weak private var toStationLabel: UILabel!
	@IBOutlet weak private var balanceNotificationLabel: UILabel!
	@IBOutlet weak private var calculatingRoutesView: UIVisualEffectView!
	@IBOutlet weak private var calculatingRoutesLabel: UILabel!
	@IBOutlet weak private var calculatingRoutesProgressIndicator: UIProgressView!
	@IBOutlet weak private var calculatingRoutesProgressDetails: UILabel!
	@IBOutlet weak private var reverseStationsButton: UIButton!
	@IBOutlet weak private var tubeMapView: Map!
	@IBOutlet weak private var calculatedRoutes: UICollectionView!
	
	// MARK: Properties
	var routing: Routing!
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.setupView()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.beginRouting()
	}
	
	// MARK: Methods
	/// Sets up the view
	private func setupView(isResetting: Bool = false) {
		self.triggerOysterReload()
		self.setupProgressViewNotifications()
		self.updateStationLabels()
		
		self.balanceNotificationLabel.alpha = 0
		self.calculatedRoutes.alpha = 0.0
		self.calculatingRoutesLabel.text = "Calculating Routes"
		self.calculatingRoutesProgressDetails.text = "Retreiving Line Status"
		
		if isResetting {
			self.tubeMapView.reset()
			DispatchQueue.main.async {
				UIView.animate(withDuration: 0.4) {
					self.calculatingRoutesView.alpha = 1
					self.calculatingRoutesProgressIndicator.setProgress(0, animated: false)
				}
			}
		} else {
			self.setupProgressView()
			self.tubeMapView.setupMap {}
		}
	}
	
	private func updateStationLabels() {
		self.fromStationLabel.text = self.routing.from.displayName
		self.toStationLabel.text = self.routing.to.displayName
	}
	
	/// Starts finding a route between two stations
	private func beginRouting() {
		DispatchQueue.main.async {
			self.calculatedRoutes.reloadData()
		}
		
		var fromStation: Stations.Station? {
			if let fromResult = self.routing.from as? Locations.StationResult {
				return fromResult.station
			} else if let fromResult = self.routing.from as? Locations.POIResult {
				return fromResult.nearestStation
			} else if let fromResult = self.routing.from as? Locations.StreetResult {
				return fromResult.nearestStation
			}
			
			return nil
		}
		
		var toStation: Stations.Station? {
			if let toResult = self.routing.to as? Locations.StationResult {
				return toResult.station
			} else if let toResult = self.routing.to as? Locations.POIResult {
				return toResult.nearestStation
			} else if let toResult = self.routing.to as? Locations.StreetResult {
				return toResult.nearestStation
			}
			
			return nil
		}
		
		if let from = fromStation, let to = toStation {
			self.tubeMapView.focusOnStations(from: from, to: to)
		}
		
		DispatchQueue.global(qos: .userInitiated).async {
			self.routing.route { (routes) in
				if !routes.isEmpty {
					print("[ChoooseJourneyViewController] \(routes.count) routes found.")
					
					DispatchQueue.main.async {
						self.calculatedRoutes.reloadData()
						self.showRoutes()
						self.teardownProgressView()
						self.tubeMapView.highlightOverview(from: routes.first!)
					}
				} else {
					print("[ChoooseJourneyViewController] No routes found.")
					DispatchQueue.main.async { self.calculatingRoutesLabel.text = "No routes found" }
				}
			}
		}
	}
	
	private func showRoutes() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.4, delay: 0.5, options: .curveLinear, animations: {
				self.calculatedRoutes.alpha = 1
				self.calculatingRoutesView.alpha = 0
				self.calculatedRoutes.alpha = 1
			})
		}
	}
	
	/// Update view based on current route
	private func updateMapData() {
		if self.routing.routes.isEmpty { return }
		
		let data = self.routing.routes[self.calculatedRoutes.indexPathsForVisibleItems.first?.section ?? 0]
		
		self.tubeMapView.showRoute(data)
		self.tubeMapView.highlightOverview(from: data)
		self.determineIfBalanceIsSufficient(for: data.fareEstimate)
	}
	
	private func triggerOysterReload() {
		Oyster.account.retrieveCards { (_, _) in }
	}

	// Check if balance is sufficient for the journey being shown on screen
	private func determineIfBalanceIsSufficient(for fare: Double) {
		if Settings().isShowingOysterInJourneys {
			Oyster.account.determineIfBalanceIsSufficient(fare: fare) { (success, balance, isSufficient) in
				guard success else { return }
				
				if balance < 0 {
					self.balanceNotificationLabel.text = "You cannot travel with a negative balance. Please top up."
				} else if !isSufficient {
					self.balanceNotificationLabel.text = "You must top up before taking this route."
				}
				
				UIView.animate(withDuration: 0.2) {
					self.balanceNotificationLabel.alpha = isSufficient ? 0 : 1
				}
			}
		}
	}
	
	private func setupProgressView() {
		self.calculatingRoutesProgressIndicator.layer.cornerRadius = self.calculatingRoutesProgressIndicator.bounds.height / 2
		self.calculatingRoutesProgressIndicator.transform = self.calculatingRoutesProgressIndicator.transform.scaledBy(x: 1, y: 2)
	}
	
	private func setupProgressViewNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "status.started"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "status.finished"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "graph.foundRoute"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "routing.startedFindingRoutes"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "routing.fastestRoutesFound"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "routing.fewestChangesRoutesFound"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "routing.lowestFareRoutesFound"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "routing.applyingFilters"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "routing.didComplete"), object: nil)
	}
	
	private func teardownProgressView() {
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "status.started"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "status.finished"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "routing.startedFindingRoutes"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "graph.foundRoute"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "routing.fastestRoutesFound"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "routing.fewestChangesRoutesFound"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "routing.lowestFareRoutesFound"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "routing.applyingFilters"), object: nil)
		
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "routing.didComplete"), object: nil)
	}
	
	@objc private func updateProgressView(notification: Notification) {
		DispatchQueue.main.async {
			switch notification.name.rawValue {
			case "status.started":
				UIView.animate(withDuration: 0.1, animations: {
					self.calculatingRoutesProgressIndicator.setProgress(0.05, animated: true)
					self.calculatingRoutesProgressDetails.text = "Fetching Line Status"
				})
			case "status.finished", "routing.startedFindingRoutes":
				UIView.animate(withDuration: 0.1) {
					self.calculatingRoutesProgressIndicator.setProgress(self.calculatingRoutesProgressIndicator.progress + 0.05, animated: true)
					self.calculatingRoutesProgressDetails.text = "Finding Fastest Routes"
				}
			case "graph.foundRoute":
				UIView.animate(withDuration: 0.1) {
					self.calculatingRoutesProgressIndicator.setProgress(self.calculatingRoutesProgressIndicator.progress + 0.03, animated: true)
				}
			case "routing.fastestRoutesFound":
				UIView.animate(withDuration: 0.1) {
					self.calculatingRoutesProgressIndicator.setProgress(self.calculatingRoutesProgressIndicator.progress + 0.1, animated: true)
					self.calculatingRoutesProgressDetails.text = "Finding Convenient Routes"
				}
			case "routing.fewestChangesRoutesFound":
				UIView.animate(withDuration: 0.1) {
					self.calculatingRoutesProgressIndicator.setProgress(self.calculatingRoutesProgressIndicator.progress + 0.1, animated: true)
					self.calculatingRoutesProgressDetails.text = "Finding Cheapest Routes"
				}
			case "routing.lowestFareRoutesFound":
			UIView.animate(withDuration: 0.1) {
				self.calculatingRoutesProgressIndicator.setProgress(self.calculatingRoutesProgressIndicator.progress + 0.1, animated: true)
				self.calculatingRoutesProgressDetails.text = "Found All Routes"
			}
			case "routing.applyingFilters":
				UIView.animate(withDuration: 0.1) {
					self.calculatingRoutesProgressIndicator.setProgress(self.calculatingRoutesProgressIndicator.progress + 0.05, animated: true)
					self.calculatingRoutesProgressDetails.text = "Applying Route Filters"
				}
			case "routing.didComplete":
				UIView.animate(withDuration: 0.2, animations: {
					self.calculatingRoutesProgressDetails.text = "Routing Complete"
					self.calculatingRoutesProgressIndicator.setProgress(1.0, animated: true)
				}) { (_) in
					self.showRoutes()
				}
			default:
				break
			}
			
			print("[ChooseJourneyViewController] Progress Indicator is at \(self.calculatingRoutesProgressIndicator.progress * 100)%")
		}
	}
	
	// MARK: Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Show Route" {
			let destVC = segue.destination as! RouteViewController
			guard let selectedIndex = self.calculatedRoutes.indexPathsForSelectedItems?.first else { return }
			
			self.routing.selectRoute(selectedIndex.section)
			
			destVC.tubeMap = self.tubeMapView
			destVC.routing = self.routing
		}
	}
	
	// MARK: IBActions
	@IBAction private func unwindToChooseJourney(_ segue: UIStoryboardSegue) { }
	
	@IBAction private func reverseStationsTapped(_ sender: UIButton) {
		self.routing = Routing(from: self.routing.to, to: self.routing.from, filters: self.routing.filters)
		
		self.setupView(isResetting: true)
		self.beginRouting()
	}
	
}

extension ChooseJourneyViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return self.routing.routes.count
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Calculated Route", for: indexPath) as! CalculatedRouteCell
		let data = self.routing.routes[indexPath.section]
		
		self.updateMapData()
		
		cell.setupCell(from: data, numberOfRoutes: self.routing.routes.count, displayingRoute: indexPath.section, timePlanning: self.routing.filters.timePlanning)
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: "Show Route", sender: self)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: collectionView.frame.width - 40, height: 150)
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		self.updateMapData()
	}
	
}

extension ChooseJourneyViewController: UIScrollViewDelegate {
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return self.tubeMapView.contentView
	}
	
}
