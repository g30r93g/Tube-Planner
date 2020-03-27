//
//  String.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 27/07/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation

extension String {
	
	/// Extracts the 16 digit bank card number from a string
	func extractCardNumber() -> String {
		var previousWasNumber: Bool = true
		var number: String = ""
		
		for char in self {
			if char.isNumber {
				number += String(char)
				previousWasNumber = true
			} else if previousWasNumber {
				previousWasNumber = false
			}
			
			if number.count == 16 { break }
		}
		
		return number
	}
	
	/// Extracts the monetary card balance from the balance
	func extractBalance() -> Double {
		var balance: String = ""
		
		var previousWasNumber: Bool = false
		for char in self {
			if char.isNumber {
				balance += String(char)
				previousWasNumber = true
			} else if previousWasNumber && char == "." {
				balance += "."
			} else if previousWasNumber {
				previousWasNumber = false
				balance = ""
				break
			}
		}
		
		guard let extractedBalance: Double = Double(balance) else { return 0.0 }
		
		return abs(extractedBalance)
	}
	
	/**
	Extracts substring from index `from` to end of
	
	- Parameter from: The index the substring starts from
	- Precondition: `from` must be greater than 0, but less than the length of the string.
	*/
	func extract(from: Int) -> String {
		let index = self.index(self.startIndex, offsetBy: min(from, self.count))
		return String(self[index...])
	}
	
}
