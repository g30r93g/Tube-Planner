//
//  EditFavouriteLocationsViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 14/10/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class EditFavouriteLocationsViewController: UIViewController {

	// MARK: IBOutlets
	@IBOutlet weak private var favouriteLocationCollection: UICollectionView!
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let deleteLongPress = UILongPressGestureRecognizer(target: self, action: #selector(deletePressHandler(gesture:)))
		deleteLongPress.minimumPressDuration = 0.6
		deleteLongPress.delaysTouchesBegan = true
		deleteLongPress.delegate = self
		self.favouriteLocationCollection.addGestureRecognizer(deleteLongPress)
	}
	
	// MARK: Methods
	/// Handles a long press for a deletion
	@objc private func deletePressHandler(gesture: UILongPressGestureRecognizer) {
		let pointPressed = gesture.location(in: self.favouriteLocationCollection)
		
		if let indexPath = self.favouriteLocationCollection.indexPathForItem(at: pointPressed) {
			let data = Journeys.shared.favouriteLocations[indexPath.item]
			
			let confirmAlert = UIAlertController(title: "Remove \(data.name)?", message: "This will delete it permanently.", preferredStyle: .alert)
			
			confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
			confirmAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (_) in
				Journeys.shared.removeFavouriteLocation(data)
				self.favouriteLocationCollection.reloadData()
			}))
			
			if self.presentedViewController == nil {
				present(confirmAlert, animated: true, completion: nil)
			} else {
				confirmAlert.dismiss(animated: false, completion: nil)
				self.present(confirmAlert, animated: true, completion: nil)
			}
		}
	}
	
	// MARK: IBActions
	/// User asked to dismiss
	@IBAction private func dismissTapped(_ sender: RoundButton) {
		self.dismiss(animated: true, completion: nil)
	}
	
	/// Reloads `favouriteLocationCollection` after unsegueing
	@IBAction private func unwindToEditingFavouriteLocations(_ segue: UIStoryboardSegue) {
		self.favouriteLocationCollection.reloadData()
	}

}

extension EditFavouriteLocationsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return Journeys.shared.favouriteLocations.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Favourite Location", for: indexPath) as! AddFavouriteLocationCell
		let data = Journeys.shared.favouriteLocations[indexPath.item]
		
		cell.setupCell(from: data)
		
		return cell
	}
	
}

extension EditFavouriteLocationsViewController: UIGestureRecognizerDelegate { }
