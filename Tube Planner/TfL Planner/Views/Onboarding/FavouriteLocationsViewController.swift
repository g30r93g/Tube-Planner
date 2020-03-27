//
//  FavouriteLocationsViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 18/09/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class FavouriteLocationsViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var favouriteLocationCollection: UICollectionView!
	
	// MARK: View Controller Life Cycle
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.updateFavouriteLocations()
	}
	
	// MARK: Methods
	private func updateFavouriteLocations() {
		self.favouriteLocationCollection.reloadData()
	}

}

extension FavouriteLocationsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
	
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
