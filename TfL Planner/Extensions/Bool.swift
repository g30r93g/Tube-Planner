//
//  Bool.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 15/11/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation

prefix operator ^
extension Bool {
	
	/// XOR
	static func ^ (left: Bool, right: Bool) -> Bool {
		return left != right
	}
	
}
