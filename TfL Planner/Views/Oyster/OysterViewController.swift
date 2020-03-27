//
//  OysterViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 16/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class OysterViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var oysterCardsCollection: UICollectionView!
	@IBOutlet weak private var journeyHistoryTable: UITableView!
	@IBOutlet weak private var loadingLabel: UILabel!
	@IBOutlet weak private var progressBar: UIProgressView!
	@IBOutlet weak private var progressDetails: UILabel!
	
	// MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		
		self.setupView()
    }
	
	// MARK: Methods
	/// Sets up the view
	private func setupView() {
		
		// Setup Gesture Recognisers
		self.setupLongPressRecogniser()
		
		// Setup Progress View
		self.setupProgressView()
		
		// Reload Oyster
		self.reloadOyster()
	}
	
	private func resetProgressDetails() {
		// Setup Loading Information Label
		self.loadingLabel.text = "Loading Oyster Account"
		
		// Setup Progress Bar
		self.progressBar.progress = 0
		
		// Setup Progress Details
		self.progressDetails.text = "Signing In"
	}
	
	private func setupLongPressRecogniser() {
		let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler(gesture:)))
		longPress.minimumPressDuration = 0.6
		longPress.delaysTouchesBegan = true
		longPress.delegate = self
		self.oysterCardsCollection.addGestureRecognizer(longPress)
	}

	/// Hide table and collection views
	private func hideDataViews() {
		self.journeyHistoryTable.alpha = 0
		self.oysterCardsCollection.alpha = 0
	}
	
	/// Triggers a reload of the oyster account
	private func reloadOyster() {
		// Setup view for reloading
		self.hideDataViews()
		self.resetProgressDetails()
		self.showLoadingLabels()
		
		// Check if network connection is available
		if !Networking.connection.isPermitted {
			// Check if networking is permitted
			if Networking.connection.isSavingData {
				self.connectionNotPermitted()
			} else {
				self.noConnection()
			}
			return
		}
		
		// Check if account details exist
		if Settings().oysterUsername == "" || Settings().oysterPassword == "" {
			self.noOysterAccount()
			return
		}
		
		// Retrieve cards
		Oyster.account.retrieveCards { (oysterCards, contactlessCards) in
			// Delay handling to allow progress bar to complete
			Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (_) in
				if !oysterCards.isEmpty || !contactlessCards.isEmpty {
					self.showOysterDetails()
				} else {
					if oysterCards.isEmpty && contactlessCards.isEmpty {
						self.noCards()
					} else {
						self.checkDetails()
					}
				}
			}
		}
	}
	
	private func showOysterDetails() {
		// Show Cards Collection
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.2) {
				self.oysterCardsCollection.reloadData()
				self.oysterCardsCollection.alpha = 1
				
				// Update Journey History Table
				self.updateJourneyHistoryTable()
			}
		}
	}
	
	private func noConnection() {
		self.showEmptyText("No Network Connection")
	}
	
	private func connectionNotPermitted() {
		self.showEmptyText("Network Tasks Restricted")
	}
	
	private func noOysterAccount() {
		self.showEmptyText("No Account Set Up")
	}
	
	private func checkDetails() {
		self.showEmptyText("Couldn't Sign In. Please try again later.")
	}
	
	private func noHistory() {
		self.showEmptyText("No Journey History")
	}
	
	private func noCards() {
		self.showEmptyText("No Cards Found")
	}
	
	private func showEmptyText(_ text: String) {
		// Update Loading Detail
		UIView.animate(withDuration: 0.2) {
			self.loadingLabel.text = text
			self.loadingLabel.alpha = 1
		}
		
		// Hide progress bar and progress detail label
		self.progressBar.alpha = 0
		self.progressDetails.alpha = 0
		self.progressDetails.text = ""
	}
	
	private func hideLoadingLabels() {
		self.loadingLabel.alpha = 0
		self.progressBar.alpha = 0
		self.progressDetails.alpha = 0
	}
	
	private func showLoadingLabels() {
		self.loadingLabel.alpha = 1
		self.progressBar.alpha = 1
		self.progressDetails.alpha = 1
	}
	
	/// Determines how to display journey history table
	/// Will either hide or show journey history table with relevant empty text if no journey is available.
	private func updateJourneyHistoryTable() {
		// Determine which card is being shown
		let visibleCardRect = CGRect(origin: self.oysterCardsCollection.contentOffset, size: self.oysterCardsCollection.bounds.size)
		let centerRect = CGPoint(x: visibleCardRect.midX, y: visibleCardRect.midY)
		
		guard let currentSection = self.oysterCardsCollection.indexPathForItem(at: centerRect)?.section else { return }
		
		// Determine if the card is type oyster or contactless and whether there is any journey history
		var journeyHistoryCount: Int {
			if Oyster.account.oysterCards.hasIndex(currentSection) {
				// Return number of oyster card history
				return Oyster.account.oysterCards.retrieve(index: currentSection)!.journeyHistory.count
			} else {
				// Return number of contactless card history
				let index = currentSection - Oyster.account.oysterCards.count
				return Oyster.account.contactlessCards.retrieve(index: index)!.journeyHistory.count
			}
		}
		
		// Animate the update
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.2, delay: 0.25, options: .curveEaseInOut, animations: {
				self.journeyHistoryTable.alpha = 0
			}) { (_) in
				if journeyHistoryCount == 0 {
					self.noHistory()
				} else {
					UIView.animate(withDuration: 0.2) {
						self.journeyHistoryTable.reloadData()
						self.journeyHistoryTable.alpha = 1
					}
				}
			}
		}
	}
	
	@objc private func longPressHandler(gesture: UILongPressGestureRecognizer!) {
		let pointPressed = gesture.location(in: self.oysterCardsCollection)
		
		if let indexPath = self.oysterCardsCollection.indexPathForItem(at: pointPressed) {
			if indexPath.section > (Oyster.account.oysterCards.count - 1) {
				// Contactless Card
				let data = Oyster.account.contactlessCards[indexPath.section - Oyster.account.oysterCards.count]
				
				let confirmAlert = UIAlertController(title: "Set card ending \(data.lastFourDigits) as favourite card?", message: "", preferredStyle: .alert)
				
				confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
				confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
					Settings().updateFavouriteCard(to: data.identifier)
				}))
				
				present(confirmAlert, animated: true, completion: nil)
			} else {
				// Oyster Card
				let data = Oyster.account.oysterCards[indexPath.section]
				
				let confirmAlert = UIAlertController(title: "Set \(data.number) as favourite oyster card?", message: "", preferredStyle: .alert)
				
				confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
				confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
					Settings().updateFavouriteCard(to: data.number)
				}))
				
				present(confirmAlert, animated: true, completion: nil)
			}
			
		}
	}
	
	// MARK: Progress View
	private func setupProgressView() {
		self.progressBar.layer.cornerRadius = self.progressBar.bounds.height / 2
		self.progressBar.transform = self.progressBar.transform.scaledBy(x: 1, y: 2)
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "oyster.finished"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "oyster.fetchedSecurityToken"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "oyster.fetchedAPITokens"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "oyster.fetchedOysterCards"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(updateProgressView(notification:)), name: Notification.Name(rawValue: "oyster.fetchedContactlessCards"), object: nil)
	}
	
	private func teardownProgressView() {
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "oyster.fetchedSecurityToken"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "oyster.fetchedAPITokens"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "oyster.fetchedOysterCards"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "oyster.fetchedContactlessCards"), object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "oyster.finished"), object: nil)
	}
	
	@objc private func updateProgressView(notification: Notification) {
		DispatchQueue.main.async {
			switch notification.name.rawValue {
			case "oyster.fetchedSecurityToken", "oyster.fetchedAPIToken":
				UIView.animate(withDuration: 0.1) {
					self.progressBar.setProgress(self.progressBar.progress + 0.15, animated: true)
					self.progressDetails.text = "Authenticating"
				}
			case "oyster.fetchedOysterCards", "oyster.fetchedContactlessCards":
				UIView.animate(withDuration: 0.1) {
					self.progressBar.setProgress(self.progressBar.progress + 0.3, animated: true)
					self.progressDetails.text = "Fetching Cards & Journey History"
				}
			case "oyster.finished":
				UIView.animate(withDuration: 0.2) {
					self.progressBar.progress = 1
					self.progressDetails.text = "Finished"
				}
			default:
				break
			}
		}
	}
	
	// MARK: Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "Show Journey Details" {
			let destVC = segue.destination as! JourneyDetailViewController
			
			let visibleRect = CGRect(origin: self.oysterCardsCollection.contentOffset, size: self.oysterCardsCollection.bounds.size)
			let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
			guard let visibleSection = self.oysterCardsCollection.indexPathForItem(at: visiblePoint)?.section else { return }
			
			if let journeyIndexPath = self.journeyHistoryTable.indexPathForSelectedRow {
				if visibleSection > (Oyster.account.oysterCards.count - 1) {
					// Contactless Card
					destVC.contactlessJourney = Oyster.account.contactlessCards[visibleSection - Oyster.account.oysterCards.count].journeyHistory[journeyIndexPath.row]
				} else {
					// Oyster Card
					destVC.oysterJourney = Oyster.account.oysterCards[visibleSection].journeyHistory[journeyIndexPath.row]
				}
			}
		}
	}
	
	// MARK: IBActions
	/// User requested to update oyster account
	@IBAction private func refreshButtonTapped(_ sender: UIBarButtonItem) {
		self.reloadOyster()
	}
	
}

extension OysterViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
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
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: collectionView.bounds.width - 40, height: 150)
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		if scrollView == self.journeyHistoryTable { return }
		
		self.hideLoadingLabels()
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if scrollView == self.journeyHistoryTable { return }
		
		self.updateJourneyHistoryTable()
	}
	
}

extension OysterViewController: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let visibleRect = CGRect(origin: self.oysterCardsCollection.contentOffset, size: self.oysterCardsCollection.bounds.size)
		let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
		guard let visibleSection = self.oysterCardsCollection.indexPathForItem(at: visiblePoint)?.section else { return 0 }
		
		if visibleSection > (Oyster.account.oysterCards.count - 1) {
			// Determine Contactless Card
			let card = Oyster.account.contactlessCards[visibleSection - Oyster.account.oysterCards.count]
			
			print("[OysterVC] Showing \(card.journeyHistory.count) journey histories for card ending \(card.lastFourDigits)")
			
			return card.journeyHistory.count
		} else {
			// Determine Oyster Card
			let card = Oyster.account.oysterCards[visibleSection]
			
			print("[OysterVC] Showing \(card.journeyHistory.count) journey histories for \(card.number)")
			
			return card.journeyHistory.count
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Oyster Journey", for: indexPath) as! OysterJourneyCell
		
		let visibleRect = CGRect(origin: self.oysterCardsCollection.contentOffset, size: self.oysterCardsCollection.bounds.size)
		let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
		guard let visibleSection = self.oysterCardsCollection.indexPathForItem(at: visiblePoint)?.section else { return cell }
		
		if visibleSection > (Oyster.account.oysterCards.count - 1) {
			// Setup Contactless Card
			let data = Oyster.account.contactlessCards[visibleSection - Oyster.account.oysterCards.count].journeyHistory[indexPath.row]
			cell.setupCell(from: data)
		} else {
			// Setup Oyster Card
			let data = Oyster.account.oysterCards[visibleSection].journeyHistory[indexPath.row]
			cell.setupCell(from: data)
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: "Show Journey Details", sender: self)
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		let visibleRect = CGRect(origin: self.oysterCardsCollection.contentOffset, size: self.oysterCardsCollection.bounds.size)
		let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
		guard let visibleSection = self.oysterCardsCollection.indexPathForItem(at: visiblePoint)?.section else { return 75 }
		
		if visibleSection > (Oyster.account.oysterCards.count - 1) {
			// Setup Contactless Card
			let data = Oyster.account.contactlessCards[visibleSection - Oyster.account.oysterCards.count].journeyHistory[indexPath.row]
			
			if data.transactionType == .bus {
				return 120
			} else {
				return 150
			}
		} else {
			// Setup Oyster Card
			let data = Oyster.account.oysterCards[visibleSection].journeyHistory[indexPath.row]
			
			if data.transactionType == .bus || data.transactionType == .topUp {
				return 120
			} else {
				return 150
			}
		}
	}
	
}

extension OysterViewController: UIGestureRecognizerDelegate { }
