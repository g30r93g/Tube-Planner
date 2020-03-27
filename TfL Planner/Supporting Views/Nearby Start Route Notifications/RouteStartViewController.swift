//
//  RouteStartViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 27/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class RouteStartViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var selectedStationsCollection: UICollectionView!
	@IBOutlet weak private var searchTextField: BorderedTextField!
	@IBOutlet weak private var matchingStationsCollection: UICollectionView!
	
	// MARK: Properties
	private var selectedStations: [Stations.Station] = [] {
		didSet {
			self.selectedStationsCollection.reloadData()
		}
	}
	
	private var matchingStations: [Stations.Station] = [] {
		didSet {
			self.matchingStationsCollection.reloadData()
		}
	}
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.setupView()
	}
	
	// MARK: Methods
	private func setupView() {
		let deleteLongPress = UILongPressGestureRecognizer(target: self, action: #selector(deletePressHandler(gesture:)))
		deleteLongPress.minimumPressDuration = 0.6
		deleteLongPress.delaysTouchesBegan = true
		deleteLongPress.delegate = self
		self.selectedStationsCollection.addGestureRecognizer(deleteLongPress)
		
		self.selectedStations = Settings().routeStartStations
		
		self.addTextFieldEvents()
	}
	
	/// Handles a long press for a deletion
	@objc private func deletePressHandler(gesture: UILongPressGestureRecognizer) {
		let pointPressed = gesture.location(in: self.selectedStationsCollection)
		
		if let indexPath = self.selectedStationsCollection.indexPathForItem(at: pointPressed) {
			let data = self.selectedStations[indexPath.item]
			
			let confirmAlert = UIAlertController(title: "Remove \(data.name)?", message: "", preferredStyle: .alert)
			
			confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
			confirmAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
				self.selectedStations.removeAll(where: {$0 == data})
			}))
			
			present(confirmAlert, animated: true, completion: nil)
		}
	}
	
	/// Adds an event listener for when text is edited
	private func addTextFieldEvents() {
		self.searchTextField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
	}
	
	// MARK: IBActions
	/// User asked to dismiss
	@IBAction private func dismissTapped(_ sender: RoundButton) {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction private func setTapped(_ sender: RoundButton) {
		Settings().setRouteStartStations(selectedStations)
		NotificationManager.session.addStationStartNotification(for: selectedStations)
		NotificationCenter.default.post(name: Notification.Name("routeStartStationsDidChange"), object: nil, userInfo: nil)
		self.dismiss(animated: true, completion: nil)
	}
	
}

extension RouteStartViewController: UIGestureRecognizerDelegate { }

extension RouteStartViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if collectionView == self.selectedStationsCollection {
			return self.selectedStations.count
		} else if collectionView == self.matchingStationsCollection {
			return self.matchingStations.count
		} else {
			return 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Station", for: indexPath) as! RouteStartStationCell
		
		var data: Stations.Station? {
			if collectionView == self.selectedStationsCollection {
				return self.selectedStations[indexPath.item]
			} else if collectionView == self.matchingStationsCollection {
				return self.matchingStations[indexPath.item]
			} else {
				return nil
			}
		}
		
		if let data = data {
			cell.setupCell(from: data)
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: (collectionView.frame.size.width - 60) / 2, height: 50)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if collectionView == self.matchingStationsCollection {
			guard let cell = collectionView.cellForItem(at: indexPath) as? RouteStartStationCell else { return }
			guard let station = cell.station else { return }
			
			if !self.selectedStations.contains(station) {
				self.selectedStations.insert(station, at: 0)
				self.searchTextField.clearText()
			}
		}
	}
	
}

extension RouteStartViewController: UITextFieldDelegate {
	
	/// Text field's content changed
	/// - parameter textField: The text field that was registered with this event
	@objc private func textFieldDidEdit(textField: UITextField) {
		// Determine the search value
		// Must be capitalised to match data set
		// Also remove any spaces or newlines to avoid data set exploitation
		guard let searchValue = textField.text?.capitalized.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
		
		// Get all stations that match the search value
		self.matchingStations = Stations.current.search(searchValue)
	}
	
}
