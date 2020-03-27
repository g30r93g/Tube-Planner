//
//  RouteOutline.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 10/09/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import Foundation
import UIKit

class RouteOutline: UIView {
	
	// MARK: Initialisers
	required init?(coder aDecoder: NSCoder) {
		self.outline = []
		self.drawnPaths = []
		
		super.init(coder: aDecoder)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.outline = []
		self.drawnPaths = []
	}
	
	// MARK: Setup Variables
	/// The preprocessed outline of the route
	private var outline: [Outline]
	
	// MARK: Setup Structs
	/// A preprocess representation of the route
	struct Outline {
		var line: Stations.Line
		var stations: [Stations.Station]
		var connections: [Stations.Connection]
	}
	
	// MARK: Setup Methods
	/// Creates an outline of the route from the instructions
	/// - parameter instructions: The human representation of instructions
	func createOutline(from instructions: [Routing.Instruction]) {
		self.reset()
		
		self.outline = instructions.filter({$0.type == .route}).map({Outline(line: $0.line!, stations: $0.stations!, connections: $0.connections!)})
		
		self.drawOutline()
	}
	
	func reset() {
		self.outline = []
		self.drawnPaths = []
		
		self.startX = 24.0
		self.endX = 0.0
		self.lineLength = 0.0
		self.lineX = 0.0
		
		guard let sublayers = self.layer.sublayers else { return }
		sublayers.forEach({$0.removeFromSuperlayer()})
	}
	
	// MARK: Drawing Variables
	/// The paths drawn and visible on the view
	private var drawnPaths: [CAShapeLayer]
	
	private var startX: CGFloat = 24.0
	private var endX: CGFloat = 0.0
	private var lineLength: CGFloat = 0.0
	private var lineX: CGFloat = 0.0
	private var lineY: CGFloat {
		return self.bounds.height / 2 - 9
	}
	
	// MARK: Drawing Methods
	/// Draws the outline of the route
	func drawOutline() {
		lineX = startX
		endX = self.bounds.width - startX
		lineLength = (endX - startX) / CGFloat(self.outline.count)
		
		for (index, outline) in self.outline.enumerated() {
			// Add Line
			let line = CAShapeLayer()
			let path = UIBezierPath()
			
			path.move(to: CGPoint(x: lineX, y: lineY))
			path.addLine(to: CGPoint(x: lineX + lineLength, y: lineY))
			
			line.lineWidth = 6
			line.lineCap = .round
			line.strokeColor = UIColor(named: outline.line.prettyName())?.cgColor ?? UIColor.gray.cgColor
			line.fillColor = UIColor(named: outline.line.prettyName())?.cgColor ?? UIColor.gray.cgColor
			line.path = path.cgPath
			
			self.drawnPaths.append(line)
			self.layer.insertSublayer(line, at: 0)
			
			// Add Inner Line if needed
			switch outline.line {
			case .dlr, .overground, .tflRail:
				let innerLine = CAShapeLayer()
				let innerPath = UIBezierPath()
				
				innerPath.move(to: CGPoint(x: lineX, y: lineY))
				innerPath.addLine(to: CGPoint(x: lineX + lineLength, y: lineY))
				
				innerLine.lineWidth = 3
				innerLine.lineCap = .round
				innerLine.strokeColor = UIColor.white.cgColor
				innerLine.fillColor = UIColor.white.cgColor
				innerLine.path = innerPath.cgPath
				
				self.drawnPaths.append(innerLine)
				self.layer.insertSublayer(innerLine, above: line)
			default:
				break
			}
			
			// Add Line Name Abbreviation
			let lineName = RoundLabel(frame: CGRect(x: lineX + (lineLength / 2) - 20, y: lineY + 10, width: 40, height: 24))
			
			lineName.cornerRadius = 5.0
			lineName.text = String(outline.line.abbreviation())
			lineName.textAlignment = .center
			lineName.font = UIFont(name: "Railway", size: 15.0)
			lineName.backgroundColor = UIColor(named: outline.line.prettyName()) ?? .gray
			lineName.textColor = .white
			lineName.clipsToBounds = true
			
			self.addSubview(lineName)
			
			// Add Line Status
			self.addLineStatus(for: outline, at: CGPoint(x: lineX + (lineLength / 2), y: lineY))
			
			// Add interchange
			if self.outline.count != index + 1 {
				self.drawInterchange(at: CGPoint(x: lineX + lineLength, y: lineY))
			}
			
			lineX += lineLength
		}
		
		self.layer.layoutIfNeeded()
		self.layoutIfNeeded()
	}
	
	/// Draws an interchange connector at the `CGPoint`
	/// - parameter point: The point at which to draw the interchange connector.
	private func drawInterchange(at point: CGPoint) {
		// Outer circle
		let circle = CAShapeLayer()
		let path = UIBezierPath(arcCenter: point, radius: 9, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)

		circle.lineWidth = 9
		circle.strokeColor = UIColor.black.cgColor
		circle.fillColor = UIColor.black.cgColor
		circle.path = path.cgPath

		// Inner Circle
		let innerCircle = CAShapeLayer()
		let innerPath = UIBezierPath(arcCenter: point, radius: 6, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)

		innerCircle.lineWidth = 6
		innerCircle.strokeColor = UIColor.white.cgColor
		innerCircle.fillColor = UIColor.white.cgColor
		innerCircle.path = innerPath.cgPath
		
		// Add to view
		self.layer.addSublayer(circle)
		self.layer.insertSublayer(innerCircle, above: circle)
	}
	
	private func addLineStatus(for outline: Outline, at point: CGPoint) {
		// Determine if user wants status shown in journeys
		if Settings().isShowingStatusInJourneys {
			// Check if line has a poor status
			guard let currentStatuses = Status.current.status.first(where: {$0.line == outline.line})?.currentStatuses else { return }
			let appropriateStatus = self.determineAppropriateStatus(from: outline, statuses: currentStatuses)
			
			switch appropriateStatus {
			case .minorDelays:
				// Draw triangle
				let triangle = CAShapeLayer()
				let trianglePath = UIBezierPath(pathString: "M1.85,21.23 C1.19761366,21.2342218 0.595190833,20.8812097 0.28,20.31 C-0.090109926,19.7488663 -0.090109926,19.0211337 0.28,18.46 L10.43,0.92 C10.7642364,0.367724267 11.3548227,0.0216482509 12,-1.17300511e-16 C12.6518037,-0.00205452223 13.2532032,0.350357922 13.57,0.92 L23.72,18.46 C24.0901099,19.0211337 24.0901099,19.7488663 23.72,20.31 C23.3857636,20.8622757 22.7951773,21.2083517 22.15,21.23 L1.85,21.23 Z")
				
				triangle.fillColor = UIColor.systemYellow.cgColor
				triangle.transform = CATransform3DMakeTranslation(point.x - 12, (point.y / 2) - 10.615, 0)
				triangle.path = trianglePath.cgPath

				// Draw Exclamation Mark
				let mark = CAShapeLayer()
				let markPath = UIBezierPath(pathString: "M11.9999878,17.1999879 C12.6627296,17.1999879 13.1999879,16.6627296 13.1999879,15.9999878 C13.1999879,15.3372461 12.6627296,14.7999878 11.9999878,14.7999878 C11.3372461,14.7999878 10.7999878,15.3372461 10.7999878,15.9999878 C10.7999878,16.6627296 11.3372461,17.1999879 11.9999878,17.1999879 Z M10.62,6.97 L10.62,9.23 L11.54,13.84 L12.46,13.84 L13.38,9.23 L13.38,6.92 C13.3640902,6.16453521 12.7554648,5.59589635 12,5.57998657 C11.2445352,5.59589635 10.6359098,6.21453521 10.62,6.97 Z")

				mark.fillColor = UIColor.black.cgColor
				mark.transform = CATransform3DMakeTranslation(point.x - 12, (point.y / 2) - 10.615, 0)
				mark.path = markPath.cgPath
				
				// Add to view
				self.layer.addSublayer(triangle)
				self.layer.insertSublayer(mark, above: triangle)
			case .severeDelays:
				// Draw triangle
				let triangle = CAShapeLayer()
				let trianglePath = UIBezierPath(pathString: "M1.85,21.23 C1.19761366,21.2342218 0.595190833,20.8812097 0.28,20.31 C-0.090109926,19.7488663 -0.090109926,19.0211337 0.28,18.46 L10.43,0.92 C10.7642364,0.367724267 11.3548227,0.0216482509 12,-1.17300511e-16 C12.6518037,-0.00205452223 13.2532032,0.350357922 13.57,0.92 L23.72,18.46 C24.0901099,19.0211337 24.0901099,19.7488663 23.72,20.31 C23.3857636,20.8622757 22.7951773,21.2083517 22.15,21.23 L1.85,21.23 Z")
				
				triangle.fillColor = UIColor.systemRed.cgColor
				triangle.transform = CATransform3DMakeTranslation(point.x - 12, (point.y / 2) - 10.615, 0)
				triangle.path = trianglePath.cgPath

				// Draw Exclamation Mark
				let mark = CAShapeLayer()
				let markPath = UIBezierPath(pathString: "M11.9999878,17.1999879 C12.6627296,17.1999879 13.1999879,16.6627296 13.1999879,15.9999878 C13.1999879,15.3372461 12.6627296,14.7999878 11.9999878,14.7999878 C11.3372461,14.7999878 10.7999878,15.3372461 10.7999878,15.9999878 C10.7999878,16.6627296 11.3372461,17.1999879 11.9999878,17.1999879 Z M10.62,6.97 L10.62,9.23 L11.54,13.84 L12.46,13.84 L13.38,9.23 L13.38,6.92 C13.3640902,6.16453521 12.7554648,5.59589635 12,5.57998657 C11.2445352,5.59589635 10.6359098,6.21453521 10.62,6.97 Z")

				mark.fillColor = UIColor.white.cgColor
				mark.transform = CATransform3DMakeTranslation(point.x - 12, (point.y / 2) - 10.615, 0)
				mark.path = markPath.cgPath
				
				// Add to view
				self.layer.addSublayer(triangle)
				self.layer.insertSublayer(mark, above: triangle)
			case .partSuspended, .suspended, .plannedClosure, .partClosure, .closed:
				// Draw red circle
				let circle = CAShapeLayer()
				let path = UIBezierPath(arcCenter: CGPoint(x: point.x, y: point.y / 2), radius: 12, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)

				circle.fillColor = UIColor.systemRed.cgColor
				circle.path = path.cgPath

				let cross = CAShapeLayer()
				let crossPath = UIBezierPath(pathString: "M13.4,12 L16.7,8.7 C16.8975245,8.52174381 17.0071418,8.26597032 17,8 C17.0178819,7.72969704 16.9182815,7.46482024 16.7267306,7.27326939 C16.5351798,7.08171855 16.270303,6.98211806 16,7 C15.7340297,6.99285825 15.4782562,7.10247546 15.3,7.3 L12,10.6 L8.7,7.3 C8.52174381,7.10247546 8.26597032,6.99285825 8,7 C7.72969704,6.98211806 7.46482024,7.08171855 7.27326939,7.27326939 C7.08171855,7.46482024 6.98211806,7.72969704 7,8 C6.99285825,8.26597032 7.10247546,8.52174381 7.3,8.7 L10.6,12 L7.3,15.3 C7.10247546,15.4782562 6.99285825,15.7340297 7,16 C6.98211806,16.270303 7.08171855,16.5351798 7.27326939,16.7267306 C7.46482024,16.9182815 7.72969704,17.0178819 8,17 C8.26597032,17.0071418 8.52174381,16.8975245 8.7,16.7 L12,13.4 L15.3,16.7 C15.4782562,16.8975245 15.7340297,17.0071418 16,17 C16.270303,17.0178819 16.5351798,16.9182815 16.7267306,16.7267306 C16.9182815,16.5351798 17.0178819,16.270303 17,16 C17.0071418,15.7340297 16.8975245,15.4782562 16.7,15.3 L13.4,12 Z")

				cross.lineWidth = 4
				cross.fillColor = UIColor.white.cgColor
				cross.transform = CATransform3DMakeTranslation(point.x - 12, (point.y / 2) - 12, 0)
				cross.path = crossPath.cgPath

				// Add to view
				self.layer.addSublayer(circle)
				self.layer.insertSublayer(cross, above: circle)
			default:
				return
			}
		}
	}
	
	/// Determines an appropriate line status to give.
	// FIXME: When whole line has minor or severe delays, status doesn't include stations and therefore won't accurately reflect line status in journeys
	private func determineAppropriateStatus(from outline: Outline, statuses: [Status.StatusSeverity]) -> Status.StatusSeverity {
		if statuses.isEmpty { return .goodService }
		
		print("[RouteOutline] Connections with not good service: \(Stations.current.stations.flatMap({$0.connections}).filter({$0.status != .goodService}).count)")
		print("[RouteOutline] Outline connections with not good service: \(outline.connections.filter({$0.status != .goodService}).count)")
		
		return outline.connections.map({$0.status}).removeDuplicates().sorted().first!
	}
	
}
