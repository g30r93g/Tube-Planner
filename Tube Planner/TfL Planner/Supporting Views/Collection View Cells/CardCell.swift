//
//  OysterCardCell.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 15/07/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class CardCell: RoundUICollectionViewCell {
	
	// MARK: IBOutlets
	@IBOutlet weak private var cardNumber: UILabel!
	@IBOutlet weak private var favouriteIndicator: UIImageView!
	@IBOutlet weak private var balanceExpiry: UILabel!
	@IBOutlet weak private var cardImage: UIImageView!
	@IBOutlet weak private var cardVendorImage: UIImageView!
	
	// MARK: Methods
	func setupCell(from data: Oyster.OysterCard) {
		self.cardNumber.text = "\(data.number)"
		
		if data.balance < 0 {
			self.balanceExpiry.text = "Balance: -£\(String(format: "%.2f", data.balance * -1))"
		} else {
			self.balanceExpiry.text = "Balance: £\(String(format: "%.2f", data.balance))"
		}
		
		self.cardImage.image = UIImage(named: "Oyster Card")
		self.cardVendorImage.image = nil
	}
	
	func setupCell(from data: Oyster.ContactlessCard) {
		self.cardNumber.text = "•••• •••• •••• \(data.lastFourDigits)"
		
		self.balanceExpiry.text = "Expiry: \(data.expiryDate)"
		
		switch data.cardType {
		case .amex:
			self.cardVendorImage.image = UIImage(named: "American Express")
			self.cardImage.image = UIImage(named: "American Express Card")
		case .mastercard:
			self.cardVendorImage.image = UIImage(named: "Mastercard")
			self.cardImage.image = UIImage(named: "Mastercard Card")
		case .visa:
			self.cardVendorImage.image = UIImage(named: "Visa")
			self.cardImage.image = UIImage(named: "Visa Card")
		case .unknown:
			break
		}
	}
	
	func isFavourite(_ isFavourite: Bool) {
		self.favouriteIndicator.alpha = isFavourite ? 1 : 0
	}
	
}
