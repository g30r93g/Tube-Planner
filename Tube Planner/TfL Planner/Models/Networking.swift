//
//  Networking.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 16/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Network

final class Networking {
	
	// MARK: Shared Instance
	static let connection = Networking()
	
	// MARK: Initialiser
	init() {
		self.monitorWifiConnection()
		self.monitorCellularConnection()
	}
	
	// MARK: Variables
	private let monitorQueue = DispatchQueue(label: "Network Monitor")
	
	/// Indicates whether the user is saving data
	public var isSavingData: Bool {
		return Settings().isSavingData
	}
	
	private var isOnWifi: Bool = false
	private var isOnCellular: Bool = false
	internal var connectionIsAvailable: Bool {
		return self.isOnWifi || isOnCellular
	}
	
	/// Indicates whether networking is permitted.
	public var isPermitted: Bool {
		if self.isSavingData {
			return self.isOnWifi
		} else {
			return self.connectionIsAvailable
		}
	}
	
	// MARK: Methods
	/// Monitors the WiFi connection on the device. Changes when WiFi connection status changes.
	private func monitorWifiConnection() {
		let wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)

		wifiMonitor.pathUpdateHandler = { (path) in
			if path.status == .satisfied {
				self.isOnWifi = true
			} else {
				self.isOnWifi = false
			}
			
			print("[Networking] Updated WiFi Connection")
		}
		
		wifiMonitor.start(queue: monitorQueue)
	}
	
	/// Monitors the Cellular connection on the device. Changes when Cellular connection status changes.
	private func monitorCellularConnection() {
		let cellularMonitor = NWPathMonitor(requiredInterfaceType: .cellular)
		
		cellularMonitor.pathUpdateHandler = { (path) in
			if path.status == .satisfied {
				self.isOnCellular = true
			} else {
				self.isOnCellular = false
			}
			
			print("[Networking] Updated Cellular Connection")
		}
		
		cellularMonitor.start(queue: monitorQueue)
	}
	
}
