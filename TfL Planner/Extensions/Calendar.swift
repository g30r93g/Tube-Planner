//
//  Calendar.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 14/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation

extension Calendar {

	/// Returns `true` if is weekend
	var isWeekend: Bool {
		return self.isDateInWeekend(Date())
	}

}
