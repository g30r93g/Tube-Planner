//
//  StatusViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 16/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class StatusViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var statusTable: UITableView!
	@IBOutlet weak private var loadingLabel: UILabel!
	@IBOutlet weak private var progressBar: UIProgressView!
	@IBOutlet weak private var progressDetails: UILabel!
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.hideProgress()
		self.setupProgressView()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.updateStatus()
	}
	
	// MARK: Methods
	/// Updates the line status from the view
	private func updateStatus() {
		// Check if network connection is available
		if !Networking.connection.isPermitted {
			// Check if networking is permitted
			if Networking.connection.isSavingData {
				self.connectionNotPermitted()
			} else {
				self.noConnection()
			}
			
			self.hideProgress()
			return
		}
		
		self.showLoadingLabels()
		self.showProgress()
		
		// Perform network update
		Status.current.updateStatus { (status) in
			DispatchQueue.main.async {
				Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (_) in
					self.hideProgress()
					
					if status.isEmpty {
						self.noStatus()
					} else {
						self.updateStatusTable()
					}
				}
			}
		}
	}
	
	private func noStatus() {
		DispatchQueue.main.async {
			self.loadingLabel.text = "No Line Status Fetched"
		}
	}
	
	private func noConnection() {
		DispatchQueue.main.async {
			self.loadingLabel.text = "No Network Connection"
		}
	}
	
	private func connectionNotPermitted() {
		DispatchQueue.main.async {
			self.loadingLabel.text = "Network Tasks Restricted"
		}
	}
	
	private func showLoadingLabels() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.2) {
				self.loadingLabel.alpha = 1
				self.progressBar.alpha = 1
				self.progressDetails.alpha = 1
			}
		}
	}
	
	private func hideLoadingLabels() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.2) {
				self.loadingLabel.alpha = 0
				self.progressBar.alpha = 0
				self.progressDetails.alpha = 0
			}
		}
	}
	
	private func hideProgress() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.2) {
				self.progressBar.alpha = 0
				self.progressDetails.alpha = 0
			}
		}
	}
	
	private func hideTable(completion: @escaping() -> Void) {
		UIView.animate(withDuration: 0.2, animations: {
			self.statusTable.alpha = 0
		}) { (_) in
			completion()
		}
	}
	
	private func showProgress() {
		UIView.animate(withDuration: 0.2) {
			self.progressBar.alpha = 1
			self.progressDetails.alpha = 1
		}
	}
	
	private func updateStatusTable() {
		// Animate the update
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.2, delay: 0.25, options: .curveEaseInOut, animations: {
				self.statusTable.reloadData()
				self.statusTable.alpha = 0
				self.hideLoadingLabels()
				self.hideProgress()
			}) { (_) in
				UIView.animate(withDuration: 0.2) {
					self.statusTable.alpha = 1
				}
			}
		}
	}
	
	// MARK: Progress View
	private func setupProgressView() {
		self.progressBar.layer.cornerRadius = self.progressBar.bounds.height / 2
		self.progressBar.transform = self.progressBar.transform.scaledBy(x: 1, y: 2)
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "status.started"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "status.currentFetched"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "status.futureFetched"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "status.finished"), object: nil)
	}
	
	private func teardownProgressView() {
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "status.started"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "status.currentFetched"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "status.futureFetched"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "status.finished"), object: nil)
	}
	
	@objc private func updateProgressView(notification: Notification) {
		DispatchQueue.main.async {
			switch notification.name.rawValue {
			case "status.started":
				UIView.animate(withDuration: 0.1) {
					self.progressBar.setProgress(0.2, animated: true)
					self.progressDetails.text = "Fetching Current and Future Statuses"
				}
			case "status.currentFetched":
				UIView.animate(withDuration: 0.1) {
					self.progressBar.setProgress(self.progressBar.progress + 0.4, animated: true)
					self.progressDetails.text = "Waiting for Future Status"
				}
			case "status.futureFetched":
				UIView.animate(withDuration: 0.1) {
					self.progressBar.setProgress(self.progressBar.progress + 0.3, animated: true)
					self.progressDetails.text = "Waiting for Current Status"
				}
			case "status.finished":
				UIView.animate(withDuration: 0.2) {
					self.progressBar.setProgress(1, animated: true)
					self.progressDetails.text = "Finished"
				}
			default:
				break
			}
		}
	}
	
	// MARK: Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Show Status Details" {
			if let indexPath = self.statusTable.indexPathForSelectedRow {
				guard let destVC = segue.destination as? StatusDetailViewController else { return }
				
				destVC.status = Status.current.status[indexPath.row]
				self.statusTable.deselectRow(at: indexPath, animated: true)
			}
		}
	}
	
	// MARK: IBActions
	/// User has requested a forced reload of the status
	@IBAction private func reloadStatus(_ sender: UIButton) {
		self.hideTable() {
			self.showLoadingLabels()
			self.updateStatus()
		}
	}
	
}

extension StatusViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return Status.current.status.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Status", for: indexPath) as! LineStatusCell
		let data = Status.current.status[indexPath.row]
		
		cell.setupCell(from: data)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: "Show Status Details", sender: self)
	}
	
}
