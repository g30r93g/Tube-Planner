//
//  URLSessionTask.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 14/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation

extension URLSessionTask {

	/// Indicates whether a URL Session Task is taking place
	var isUpdating: Bool {
		switch self.state {
		case .running:
			return true
		default:
			return false
		}
	}

}
