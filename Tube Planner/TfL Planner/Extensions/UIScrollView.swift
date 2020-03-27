//
//  UIScrollView.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 15/11/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

extension UIScrollView {
	
	/// Scrolls to the bottom of the scroll view
	/// - parameter animated: Whether to animate scrolling
    func scrollToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: contentOffset.x, y: contentSize.height - bounds.height + adjustedContentInset.bottom)
		self.setContentOffset(bottomOffset, animated: animated)
    }
	
	/// Zooms to the specified point in the scroll view's zoomable content view.
	/// - parameter scale: A value between minimumZoomScale and maximumZoomScale to zoom to
	func zoom(to point: CGPoint, scale: CGFloat) {
		// Enusre scale is a value that is within the permitted zoom scale
		var scale = CGFloat.minimum(scale, maximumZoomScale)
		scale = CGFloat.maximum(scale, self.minimumZoomScale)
		
		// Work out the current zoom scale and where we're zooming to
		var translatedZoomPoint: CGPoint = .zero
		translatedZoomPoint.x = point.x + self.contentOffset.x
		translatedZoomPoint.y = point.y + self.contentOffset.y
		
		// Calculate the correct zoom scale
		let zoomFactor = 1.0 / self.zoomScale
		
		translatedZoomPoint.x *= zoomFactor
		translatedZoomPoint.y *= zoomFactor
		
		var destinationRect: CGRect = .zero
		destinationRect.size.width = self.frame.width / scale
		destinationRect.size.height = self.frame.height / scale
		destinationRect.origin.x = translatedZoomPoint.x - destinationRect.width * 0.5
		destinationRect.origin.y = translatedZoomPoint.y - destinationRect.height * 0.5
		
		UIView.animate(withDuration: 0.4) {
			self.zoom(to: destinationRect, animated: true)
		}
	}
	
}
