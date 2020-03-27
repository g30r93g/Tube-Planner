//
//  LoadingRing.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 03/01/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class LoadingRing: RoundView {
	
	// MARK: View Lifecycle
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.cornerRadius = self.frame.width / 2
	}
	
	// MARK: Properties
	private var progressLayer: CAShapeLayer!
	
	// MARK: Drawing Methods
	public func startLoading(with timeInterval: TimeInterval, completion: @escaping() -> Void) {
		self.progressLayer = CAShapeLayer()
		
		let circularPath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0), radius: frame.size.width / 2.0, startAngle: (3 * .pi) / 2, endAngle: -.pi / 2, clockwise: false)
		
		self.progressLayer.path = circularPath.cgPath
		self.progressLayer.fillColor = UIColor.clear.cgColor
		self.progressLayer.lineCap = .round
		self.progressLayer.lineWidth = 2
		self.progressLayer.strokeEnd = 0
		self.progressLayer.strokeColor = UIColor(named: "Accent 1")?.cgColor ?? UIColor.yellow.cgColor
		
		self.layer.addSublayer(progressLayer)
		
		self.animate(for: timeInterval)
		
		Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { (_) in
			completion()
		}
	}
	
	private func animate(for duration: TimeInterval) {
		let animation = CABasicAnimation(keyPath: "strokeEnd")
		
		animation.duration = duration
		animation.fromValue = 1
		animation.toValue = 0
		animation.fillMode = .backwards
		animation.isRemovedOnCompletion = true
		
		progressLayer.add(animation, forKey: "progressAnim")
	}
	
}
