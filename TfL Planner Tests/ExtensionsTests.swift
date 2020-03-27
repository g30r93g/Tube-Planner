//
//  ExtensionsTests.swift
//  TfL PlannerTests
//
//  Created by George Nick Gorzynski on 23/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import XCTest
@testable import TfL_Planner

// TODO: Use RegEx to determine if strings are correct
class DateTests: XCTestCase {
	
	let isoString = "2020-02-03T12:05:05+0000"
	
	func testISOInit() {
		let isoDate = Date(isoDate: isoString)
		let components = isoDate.dateComponents()
		
		XCTAssert(components.year == 2020)
		XCTAssert(components.month == 2)
		XCTAssert(components.day == 3)
		XCTAssert(components.hour == 12)
		XCTAssert(components.minute == 5)
	}
	
	func testIsNightTube() {
		let nightTubeDate = Date(isoDate: "2020-02-22T04:30:00+0000")
		
		XCTAssertTrue(nightTubeDate.isNightTube())
	}
	
	func testDateIsToday() {
		let dateToday = Date()

		XCTAssertTrue(dateToday.isToday())
	}
	
	func testUsingTime() {
		let date = Date()
		let components = date.dateComponents()
		
		let customDate = Date().usingTime(0, 0, 0)
		let customComponents = customDate.dateComponents()
		
		XCTAssert(components.year == customComponents.year)
		XCTAssert(components.month == customComponents.month)
		XCTAssert(components.day == customComponents.day)
		XCTAssert(components.hour != customComponents.hour)
		XCTAssert(components.minute != customComponents.minute)
	}
	
	// func fallsIn(lower:_, upper:_) -> Bool
	func testDateFallsInRange() {
		let morning = Date().usingTime(7, 30, 00)
		let lunch = Date().usingTime(12, 00, 00)
		let meeting = Date().usingTime(10, 45, 00)
		
		XCTAssertTrue(meeting.fallsIn(lower: morning, upper: lunch))
	}
	
	func testDateIsWithin() {
		XCTAssertTrue(Date().isWithin(10))
	}
	
	// func isOld(_ seconds:_) -> Bool
	func testDateIsOld() {
		let lastFetch = Date().usingTime(7, 30, 00)
		let currentTime = Date().usingTime(12, 00, 00)
		
		XCTAssertTrue(currentTime.isOld(by: 300, comparedTo: lastFetch))
	}
	
	func testISOFormat() {
		let isoDate = Date(isoDate: isoString)
		
		XCTAssertEqual("2020-02-03T12:05:05Z", isoDate.isoFormat())
	}
	
	func testTfLJourneyFormat() {
		let isoDate = Date(isoDate: isoString)
		
		XCTAssertEqual("2020-02-03", isoDate.tflJourneyFormat())
	}
	
	func testDateString() {
		let isoDate = Date(isoDate: isoString)
		
		XCTAssertEqual("3 Feb 2020", isoDate.date())
	}
	
	func testDay() {
		let isoDate = Date(isoDate: isoString)
		
		XCTAssertEqual(1, isoDate.day())
	}
	
	func testTime() {
		let isoDate = Date(isoDate: isoString)
		
		XCTAssertEqual("12:05", isoDate.time())
	}
	
	func testHour() {
		let isoDate = Date(isoDate: isoString)
		
		XCTAssertEqual(12, isoDate.hour())
	}
	
	func testMinute() {
		let isoDate = Date(isoDate: isoString)
		
		XCTAssertEqual(5, isoDate.minute())
	}
	
	func testFriendlyFormat() {
		let isoDate = Date(isoDate: isoString)
		
		XCTAssertEqual("3 Feb 2020 at 12:05", isoDate.friendlyFormat())
	}
	
}

class ArrayTests: XCTestCase {
	
	/// func retrieve(index:) -> Element?
	func testRetrieve() {
		var testArray: [String] = []
		
		XCTAssertNil(testArray.retrieve(index: 0))
		
		testArray = ["A"]
		
		XCTAssert(testArray.retrieve(index: 0) == "A")
	}
	
	/// mutating func removeAllButLast()
	func testRemoveAllButLast() {
		var testArray = ["A", "B", "C", "D"]
		testArray.removeAllButLast()
		
		XCTAssert(testArray.count == 1)
		XCTAssert(testArray.last == "D")
	}
	
	func testMove() {
		var testArray = ["A", "B", "C", "D"]
		testArray.move(index: 0, to: 3)
		
		XCTAssert(testArray.count == 4)
		XCTAssert(testArray.last == "A")
	}
	
	func testHasIndex() {
		let testArray = ["A", "B", "C", "D"]
		
		XCTAssertTrue(testArray.hasIndex(0))
		XCTAssertFalse(testArray.hasIndex(4))
	}
	
	func testUniquelyAppend() {
		var testArray = ["A", "B", "C", "D"]
		
		let initialCount = testArray.count
		testArray.uniquelyAppend("A")
		
		XCTAssert(initialCount == testArray.count)
		
		testArray.uniquelyAppend("E")
		
		XCTAssert(initialCount < testArray.count)
		XCTAssert(initialCount + 1 == testArray.count)
	}
	
	/// mutating func removeDuplicateStatuses()
	func testRemoveDuplicateStatuses() {
		var testArray = ["A", "A", "B", "C", "D", "C", "D"]
		testArray.removeDuplicateStatuses()
		
		XCTAssert(testArray.count == 4 && testArray == ["A", "B", "C", "D"])
	}
	
	/// mutating func removeConsecutiveDuplicates()
	func testRemoveConsecutiveDuplicates() {
		var testArray =  ["A", "A", "A", "B", "C", "C", "C", "D", "D", "C", "C", "C"]
		testArray = testArray.removeConsecutiveDuplicates()
		
		XCTAssert(testArray.count == 5 && testArray == ["A", "B", "C", "D", "C"])
	}
	
	func testRemoveDuplicates() {
		var testArray =  ["A", "A", "A", "B", "C", "C", "C", "D", "D", "C", "C", "C"]
		testArray = testArray.removeDuplicates()
		
		XCTAssert(testArray == ["A", "B", "C", "D"])
	}
	
}

class URLSessionTaskTests: XCTestCase {
	
	// var isUpdating: Bool
	func testIsUpdating() {
		do {
			try XCTSkipIf(!Networking.connection.connectionIsAvailable, "No network connection")
			
			guard let googleURL = URL(string: "https://www.google.co.uk/") else { XCTFail(); return }
			let googleSessionTask: URLSessionTask! = URLSession.shared.dataTask(with: googleURL) { (_, response, error) in
				guard let response = (response as? HTTPURLResponse)?.statusCode else { XCTFail(); return }
				if error != nil || response != 200 {
					XCTFail()
				} else {
					XCTAssertTrue(true)
				}
			}
			googleSessionTask.resume()
			
			XCTAssertTrue(googleSessionTask.isUpdating)
		} catch let error {
			print(error)
		}
	}
	
}

class StringTests: XCTestCase {
	
	// func extractCardNumber() -> String
	func testExtractingCardNumber() {
		let testStringA = "1234567890123456"
		XCTAssert(testStringA.extractCardNumber() == "1234567890123456")
		
		let testStringB = " adsdfds --&&$*@#()"
		XCTAssert(testStringB.extractCardNumber() == "")
		
		let testStringC = testStringA + testStringB
		XCTAssert(testStringC.extractCardNumber() == "1234567890123456")
		
		let testStringD = testStringB + testStringA
		XCTAssert(testStringD.extractCardNumber() == "1234567890123456")
	}
	
	// func extractBalance() -> Double
	func testExtractingBalance() {
		let testString = "£12.34"
		
		XCTAssert(testString.extractBalance() == 12.34)
	}
	
	// func extract -> String {
	func testExtract() {
		let testString = "Hello World!"
		let extractedString = testString.extract(from: 6)
		
		XCTAssert(extractedString == "World!")
	}
	
}

class BoolTests: XCTestCase {
	
	// static func ^ (left:_, right:_) -> Bool
	func testXOR() {
		XCTAssert(true ^ false)
	}
	
}

class CalendarTests: XCTestCase {
	
	// var isWeekend: Bool
	func testIsWeekend() {
		let isWeekendFromDateComponents = Date().day() == 6 || Date().day() == 7
		
		XCTAssertEqual(isWeekendFromDateComponents, Calendar.current.isWeekend)
	}
	
}
