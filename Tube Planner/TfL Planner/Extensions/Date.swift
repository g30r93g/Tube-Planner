//
//  Date.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 14/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation

extension Date {
	
	init(isoDate: String) {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		
		self = dateFormatter.date(from: isoDate) ?? Date()
	}
	
	func isNightTube() -> Bool {
		// Night tube runs on friday into saturday, and saturday into sunday
		return (self.day() == 6 || self.day() == 7) && self.hour() < 5
	}
	
	/// Date formatting for oyster cards in oyster API
	static func card(dateString: String) -> Date {
		let formatter = DateFormatter()
		
		formatter.dateFormat = "MM/dd/yyyy HH:mm:ss a '+00:00'"
		formatter.locale = Locale(identifier: "en_gb")
		
		return formatter.date(from: dateString)!
	}
	
	// Date formatting for oyster API journeys
	static func journeys(dateString: String) -> Date {
		let formatter = DateFormatter()
		
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'"
		formatter.locale = Locale(identifier: "en_gb")
		
		return formatter.date(from: dateString)!
	}
	
	/// Determines if the date is today's date
	func isToday() -> Bool {
		return self.usingTime(0, 0, 0) == Date().usingTime(0, 0, 0)
	}
	
	/// Uses the current date, but manipulates the time value
	func usingTime(_ hour: Int, _ minute: Int, _ second: Int) -> Date {
		let calendar = Calendar(identifier: .gregorian)
		
		var dateComponents = calendar.dateComponents([.year, .month, .day], from: self)
		dateComponents.hour	= hour
		dateComponents.minute = minute
		dateComponents.second = second
		
		return calendar.date(from: dateComponents)!
	}
	
	/// Determines whether the current date falls in the range of two dates
	func fallsIn(lower: Date, upper: Date) -> Bool {
		return self >= lower && self <= upper
	}
	
	/// Determines if the current time is within the specified number of seconds
	func isWithin(_ seconds: TimeInterval) -> Bool {
		return self.fallsIn(lower: self, upper: self.addingTimeInterval(seconds))
	}
	
	/// Returns an ISO-8601 date
	func isoFormat() -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
		
		return dateFormatter.string(from: self).appending("Z")
	}
	
	/// Formats the date yyyy-MM-dd, as TfL does
	func tflJourneyFormat() -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
		
		return dateFormatter.string(from: self)
	}
	
	/// Returns the date
	func date() -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.locale = Locale(identifier: "en_UK")
		
		return dateFormatter.string(from: self)
	}
	
	/// Returns the day index
	/// Days start counting from Monday where Monday is day 1
	func day() -> Int {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEEE"
		dateFormatter.locale = Locale(identifier: "en_UK")
		
		let dayName = dateFormatter.string(from: self).lowercased()
		
		switch dayName {
		case "monday":
			return 1
		case "tuesday":
			return 2
		case "wednesday":
			return 3
		case "thursday":
			return 4
		case "friday":
			return 5
		case "saturday":
			return 6
		case "sunday":
			return 7
		default:
			return 0
		}
	}
	
	/// Returns the time
	func time() -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH:mm"
		
		return dateFormatter.string(from: self)
	}
	
	/// Returns the hour
	func hour() -> Int {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH"
		
		return Int(dateFormatter.string(from: self)) ?? 0
	}
	
	/// Returns the minute
	func minute() -> Int {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "mm"
		
		return Int(dateFormatter.string(from: self)) ?? 0
	}
	
	/// Determines if the date provided is older than a time period
	func isOld(by seconds: Double, comparedTo: Date = Date()) -> Bool {
		// If comparison date is older than the date, return true
		return comparedTo <= self.addingTimeInterval(seconds * -1)
	}
	
	/// Prettifies a date
	func friendlyFormat() -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = .short
		dateFormatter.dateStyle = .medium
		dateFormatter.locale = Locale(identifier: "en_UK")
		
		return dateFormatter.string(from: self)
	}
	
	/// Returns tomorrow's date using a given time
	func tomorrow(hour: Int, minute: Int, second: Int) -> Date {
		return Calendar.current.date(byAdding: .day, value: 1, to: self)!.usingTime(hour, minute, second)
	}
	
	/// Returns next week's date using a given time
	func nextWeek(hour: Int, minute: Int, second: Int) -> Date {
		return Calendar.current.date(byAdding: .day, value: 7, to: self)!.usingTime(hour, minute, second)
	}
	
	/// Returns last week's date
	func lastWeek() -> Date {
		return Calendar.current.date(byAdding: .day, value: -6, to: self)!
	}
	
	/// Returns date from 31 days ago
	func lastMonth() -> Date {
		return Calendar.current.date(byAdding: .day, value: -30, to: self)!
	}
	
	func dateComponents() -> DateComponents {
		return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)
	}
	
}
