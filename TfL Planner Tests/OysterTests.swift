//
//  OysterTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
@testable import TfL_Planner

class OysterTests: XCTestCase {
	
	var oyster: Oyster!
	
	override func setUp() {
		self.oyster = Oyster()
	}
	
	func useCorrectAccount() {
		Settings().changeOysterUsername(to: "georgegorzynski@me.com")
		Settings().changeOysterPassword(to: "JeuyfMz36WqY")
	}
	
	func useIncorrectAccount() {
		Settings().changeOysterUsername(to: "incorrect")
		Settings().changeOysterPassword(to: "phony")
	}
	
	func testValidateOysterAccount_IncorrectAccount() {
		self.useIncorrectAccount()
		
		self.oyster.validateOysterAccount { (isValid) in
			XCTAssertFalse(isValid)
		}
		
		self.useCorrectAccount()
	}
	
	func testValidateOysterAccount_CorrectAccount() {
		self.useCorrectAccount()
		
		self.oyster.validateOysterAccount { (isValid) in
			XCTAssertTrue(isValid)
		}
	}
	
	func testGetFavouriteCard() {
		self.useCorrectAccount()
		Settings().updateFavouriteCard(to: "011880355513")
		
		self.oyster.retrieveFavouriteOysterCard { (card) in
			XCTAssertNotNil(card)
		}
	}
	
	func testDetermineIfBalanceIsSufficient() {
		self.useCorrectAccount()
		Settings().updateFavouriteCard(to: "011880355513")
		
		let fare: Double = 0.00
		
		self.oyster.determineIfBalanceIsSufficient(fare: fare) { (success, balance, sufficient) in
			XCTAssertTrue(success)
			XCTAssertGreaterThanOrEqual(balance, fare)
			XCTAssertTrue(sufficient)
		}
	}
	
	
	func testRetrieveCards() {
		self.useCorrectAccount()
		
		self.oyster.retrieveCards { (oysterCards, contactlessCards) in
			XCTAssertFalse(oysterCards.isEmpty)
			XCTAssertFalse(contactlessCards.isEmpty)
		}
	}
	
}
