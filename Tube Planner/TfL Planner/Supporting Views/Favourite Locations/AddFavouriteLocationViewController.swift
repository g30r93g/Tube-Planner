//
//  AddFavouriteLocationViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 27/09/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import MapKit
import UIKit

class AddFavouriteLocationViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var locationLabel: UILabel!
	@IBOutlet weak private var mapView: MKMapView!
	@IBOutlet weak private var crosshair: UIImageView!
	@IBOutlet weak private var searchField: UITextField!
	@IBOutlet weak private var findButton: UIButton!
	@IBOutlet weak private var locationsCollection: UICollectionView!
	
	// MARK: Properties
	private var locationResults: [Locations.LocationResult] = [] {
		didSet {
			self.locationsCollection.reloadData()
		}
	}
	private var selectedResult: Locations.LocationResult?
	private var locationName: String = ""
	
	// MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		
		self.setupView()
    }
	
	var mapLocationCoords: CLLocationCoordinate2D!
	
	// MARK: Methods
	private func setupView() {
		self.setMapToCurrentLocation()
		self.addTextFieldEvents()
		
		self.locationsCollection.delegate = self
		self.locationsCollection.dataSource = self
		
		self.locationLabel.text = ""
	}
	
	/// Position map on user's current location.
	private func setMapToCurrentLocation() {
		let userLocation = UserLocation.current.updateLocation() ?? CLLocation(latitude: 51.509865, longitude: -0.118092)
		
		let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
		
        self.mapView.setRegion(region, animated: false)
	}
	
	private func addTextFieldEvents() {
		self.searchField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
	}
	
	private func hideMap() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.4) {
				self.mapView.alpha = 0
				self.crosshair.alpha = 0
			}
			self.searchField.becomeFirstResponder()
		}
	}
	
	private func showMap() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.4) {
				self.mapView.alpha = 1
				self.crosshair.alpha = 1
			}
		}
		self.searchField.resignFirstResponder()
	}
	
	private func switchFindButton(_ sender: UIButton) {
		if sender.titleLabel!.text == "Find" {
			sender.setTitle("Map", for: .normal)
			sender.setImage(UIImage(systemName: "map.fill"), for: .normal)
			
			self.hideMap()
		} else {
			sender.setTitle("Find", for: .normal)
			sender.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
			
			self.showMap()
		}
	}
	
	// MARK: IBActions
	// User want's to dismiss the view controller
	@IBAction private func dismissTapped(_ sender: UIButton) {
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction private func findTapped(_ sender: UIButton) {
		self.switchFindButton(sender)
	}
	
	/// User wants to confirm adding a new favourite location
	@IBAction private func addLocationTapped(_ sender: UIButton) {
		let selectedLocation = self.selectedResult as? Locations.StreetResult ?? Locations.StreetResult(displayName: "", address: "", placemark: MKPlacemark(coordinate: self.mapView.centerCoordinate))
		
		let alert = UIAlertController(title: "Set Location Name", message: nil, preferredStyle: .alert)
		
		alert.addTextField { (textField) in
			textField.clearButtonMode = .always
			
			if !self.locationLabel.text!.isEmpty {
				textField.text = self.locationLabel.text
			}
			
			textField.delegate = self
			textField.addTarget(self, action: #selector(self.textFieldDidEdit(textField:)), for: .editingChanged)
		}
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
			alert.dismiss(animated: true, completion: nil)
		}))
		
		alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (_) in
			Journeys.shared.addFavouriteLocation(location: selectedLocation, withName: self.locationName.isEmpty ? selectedLocation.displayName : self.locationName)
			NotificationCenter.default.post(name: Notification.Name("favouriteLocations.newLocationAdded"), object: nil, userInfo: nil)
			self.performSegue(withIdentifier: "Finish Adding Location", sender: self)
		}))
		
		self.present(alert, animated: true, completion: nil)
	}

}

extension AddFavouriteLocationViewController: MKMapViewDelegate { }

extension AddFavouriteLocationViewController: UITextFieldDelegate {
	
	/// Text field's content changed
	/// - parameter textField: The text field that was registered with this event
	@objc private func textFieldDidEdit(textField: UITextField) {
		if textField == self.searchField {
			guard let text = textField.text else { return }
			
			self.locationResults.removeAll()
			
			Locations.shared.findPOIs(matching: text).forEach({self.locationResults.uniquelyAppend(Locations.LocationResult(type: .poi, displayName: $0.displayName, coordinates: $0.coordinate))})
			
			if text.count < 3 { return }
			
			Locations.shared.findMapLocations(matching: text) { (locations) in
				if locations.isEmpty { return }
				
				locations.forEach({self.locationResults.uniquelyAppend($0)})
			}
		} else {
			guard let text = textField.text else { return }
			
			self.locationName = text
		}
	}
	
}

extension AddFavouriteLocationViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.locationResults.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Matching Location", for: indexPath) as! MatchingLocationCell
		let data = self.locationResults[indexPath.item]
		
		if let poi = data as? Locations.POIResult {
			cell.setupCell(from: poi)
		} else if let street = data as? Locations.StreetResult {
			cell.setupCell(from: street)
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let location = self.locationResults[indexPath.item]
		
		self.selectedResult = location
		
		self.switchFindButton(self.findButton)
		self.mapView.setCenter(location.coordinates, animated: false)
		self.locationLabel.text = location.displayName
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: UIScreen.main.bounds.width - 54, height: 75)
	}
	
}
