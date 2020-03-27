//
//  ChooseFavouriteCardViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 16/02/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class ChooseFavouriteCardViewController: UIViewController {

	// MARK: IBOutlets
	@IBOutlet weak private var loadingIndicator: UIActivityIndicatorView!
	@IBOutlet weak private var cardCollectionView: UICollectionView!
	@IBOutlet weak private var done: UIButton!
	
	// MARK: Properties
	private var selectedIndex: IndexPath? {
		didSet {
			var indexPaths: [IndexPath] = []
			
			if let selectedIndex = selectedIndex {
				indexPaths.append(selectedIndex)
			}
			
			if let oldValue = oldValue {
				indexPaths.append(oldValue)
			}
			
			self.cardCollectionView.performBatchUpdates( {
				self.cardCollectionView.reloadItems(at: indexPaths)
			}) { (_) in
				if let selectedIndex = self.selectedIndex {
					self.cardCollectionView.scrollToItem(at: selectedIndex, at: .centeredVertically, animated: true)
				}
			}
		}
	}
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
        // Do any additional setup after loading the view.
		
		self.cardCollectionView.allowsSelection = true
		self.cardCollectionView.allowsMultipleSelection = false
		self.updateDoneUserInteraction()
		self.fetchCards()
    }
	
	// MARK: Methods
	private func updateDoneUserInteraction() {
		// Update UI
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.4) {
				self.done.isUserInteractionEnabled = self.selectedIndex != nil
				self.done.isEnabled = self.selectedIndex != nil
				self.done.alpha = self.selectedIndex != nil ? 1 : 0.5
			}
		}
	}
	
	private func fetchCards() {
		self.startLoading()
		
		Oyster.account.retrieveCards { (_, _) in
			DispatchQueue.main.async {
			self.cardCollectionView.reloadData()
			self.determineIfShouldSkip()
			self.stopLoading()
			}
		}
	}
	
	/// Start animating `loadingIndicator`
	private func startLoading() {
		DispatchQueue.main.async {
			self.loadingIndicator.startAnimating()
		}
	}
	
	/// Stop animating `loadingIndicator`
	private func stopLoading() {
		DispatchQueue.main.async {
			self.loadingIndicator.stopAnimating()
		}
	}
	
	private func determineIfShouldSkip() {
		if Oyster.account.oysterCards.count + Oyster.account.contactlessCards.count == 0 {
			// Skip because user cannot select any card
			DispatchQueue.main.async {
			self.performSegue(withIdentifier: "Finish Selecting Card", sender: self)
			}
		} else {
			self.updateDoneUserInteraction()
		}
	}
	
	private func saveFavouriteCard() {
		guard let selectedIndex = self.selectedIndex?.item else { return }
		
		if selectedIndex > (Oyster.account.oysterCards.count - 1) {
			// Contactless Card
			let data = Oyster.account.contactlessCards[selectedIndex - Oyster.account.oysterCards.count]
			
			Settings().updateFavouriteCard(to: data.identifier)
		} else {
			// Oyster Card
			let data = Oyster.account.oysterCards[selectedIndex]
			
			Settings().updateFavouriteCard(to: data.number)
		}
	}
	
	// MARK: IBActions
	@IBAction private func doneTapped(_ sender: UIButton) {
		// Save favourited card
		self.saveFavouriteCard()
		
		// Perform unwind segue to original view
		self.performSegue(withIdentifier: "Finish Selecting Card", sender: self)
	}

}

// MARK: Collection View Delegates
extension ChooseFavouriteCardViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		let count = Oyster.account.oysterCards.count + Oyster.account.contactlessCards.count
		print("[OysterVC] Number of cards to display: \(count)")
		
		return count
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Card", for: indexPath) as! CardCell
		
		if indexPath.section > (Oyster.account.oysterCards.count - 1) {
			// Setup Contactless Card
			let data = Oyster.account.contactlessCards[indexPath.section - Oyster.account.oysterCards.count]
			cell.setupCell(from: data)
		} else {
			// Setup Oyster Card
			let data = Oyster.account.oysterCards[indexPath.section]
			cell.setupCell(from: data)
		}
		
		cell.isFavourite(indexPath == self.selectedIndex)
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		self.selectedIndex = indexPath
		
		self.updateDoneUserInteraction()
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: collectionView.bounds.width - 40, height: 150)
	}
	
}
