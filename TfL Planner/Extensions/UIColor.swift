//
//  UIColor.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 10/10/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

extension UIColor {
	
	// Changes the brightness of the color
	private func changeBrightness(by factor: CGFloat) -> UIColor {
		var hue: CGFloat = 0
		var saturation: CGFloat = 0
		var brightness: CGFloat = 0
		var alpha: CGFloat = 0
		
		if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
			return UIColor(hue: hue, saturation: saturation, brightness: (brightness * factor), alpha: alpha)
		} else {
			return self
		}
	}
	
	/// Returns a color that has a brightness of 0.8 the original value
	func glow() -> UIColor {
		return self.changeBrightness(by: 0.8)
	}
	
	/// Returns a color that has a brightness of 0.5 the original value
	func darken() -> UIColor {
		return self.changeBrightness(by: 0.5)
	}
	
}
