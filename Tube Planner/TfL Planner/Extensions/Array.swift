//
//  Array.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 10/10/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation

extension Array {
	
	func retrieve(index: Int) -> Element? {
		if index < self.count {
			return self[index]
		} else {
			return nil
		}
	}
	
	/// Removes all elements apart from the last one
	mutating func removeAllButLast() {
		guard let last = self.last else { return }
		self = [last]
	}
	
	/// Moves an item in an array
	mutating func move(index: Int, to newIndex: Int) {
		self.insert(self.remove(at: index), at: newIndex)
	}
	
	/// Determines if the array contains an index
	func hasIndex(_ index: Int) -> Bool {
		return self.retrieve(index: index) != nil
	}
	
}

extension Array where Element: Equatable {
	
	mutating func uniquelyAppend(_ element: Element) {
		if !self.contains(element) {
			self.append(element)
		}
	}
	
	/// Removes duplicate statuses from the line status
	/// Specifically for `Status` class
	mutating func removeDuplicateStatuses() {
		var result: [Element] = []
		
        for element in self {
            if !result.contains(element) {
                result.append(element)
            }
        }
		
        self = result
    }
	
	func removeConsecutiveDuplicates() -> [Element] {
		var result: [Element] = []
		
		for (index, element) in self.enumerated() {
			if index == 0 { result.append(element); continue }
			
			guard let last = result.last else { continue }
			if last != element {
                result.append(element)
            }
        }
		
		return result
	}
	
}

extension Array where Element: Hashable {
	
	/// Removes any duplicate items in an array
	///  - Returns: An array with no duplicates
    func removeDuplicates() -> [Element] {
		var addedDict: [Element : Bool] = [:]
		
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
}
