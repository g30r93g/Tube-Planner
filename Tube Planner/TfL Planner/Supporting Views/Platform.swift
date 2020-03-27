//
//  Platform.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 04/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class Platform: UIView {
	
	// MARK: IBOutlet
	@IBOutlet weak private var stationName: UILabel!
	@IBOutlet weak private var direction: UILabel!
	@IBOutlet weak private var nextArrivals: UITableView!
	
	// MARK: View Life Cycle
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.setupView()
	}
	
	// MARK: Properties
	private(set) var arrivals: Arrivals!
	private(set) var station: Stations.Station!
	private(set) var line: Stations.Line!
	private(set) var heading: Stations.Direction!
	
	private var refreshTimer: Timer!
	
	// MARK: Methods
	private func setupView() {
		// Set Delegates
		self.nextArrivals.dataSource = self
		self.nextArrivals.delegate = self
	}
	
	public func hide() {
		self.arrivals = nil
		self.station = nil
		self.line = nil
		self.heading = nil
		
		self.stationName.text = ""
		self.direction.text = ""
		self.nextArrivals.reloadData()
	}
	
	// MARK: Arrivals Methods
	public func updateWith(station: Stations.Station, line: Stations.Line, heading: Stations.Direction) {
		self.station = station
		self.line = line
		self.heading = heading
		
		self.stationName.text = station.name
		self.direction.text = heading.rawValue
	}
	
	private func retrieveArrivals() {
		self.arrivals = Arrivals(station: station, line: line, direction: heading)
		
		self.arrivals.getArrivals { (arrivals) in
			if !arrivals.isEmpty {
				DispatchQueue.main.async {
					self.nextArrivals.reloadData()
					
					UIView.animate(withDuration: 0.2) {
						self.nextArrivals.alpha = 1
					}
				}
			} else {
				print("[Platform] No arrivals found. Please check platform and front of trains.")
				DispatchQueue.main.async {
					UIView.animate(withDuration: 0.2) {
						self.nextArrivals.alpha = 0
					}
				}
			}
		}
	}
	
	public func stopTimer() {
		guard self.refreshTimer != nil else { return }
		self.refreshTimer.invalidate()
		self.refreshTimer = nil
		
		self.arrivals.stop()
	}
	
	public func startTimer() {
		self.refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { (_) in
			print("\n[Platform] Refreshing Arrivals at \(self.station.name)")
			self.retrieveArrivals()
		})
		
		self.refreshTimer.fire()
	}
		
}

extension Platform: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let arrivals = self.arrivals {
			return arrivals.nextArrivals.count
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Next Arrival", for: indexPath) as! NextArrivalCell
		
		cell.setupCell(from: self.arrivals.nextArrivals[indexPath.row])
		
		return cell
	}
	
}
