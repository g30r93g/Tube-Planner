//
//  InteractiveMap.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 01/07/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import SwiftSVG
import UIKit

/// An interactive tube map that dynamically changes based on the data fed to it
class Map: UIScrollView {
	
	// MARK: IBInspectables
	@IBInspectable var requiresInset: Bool = false {
		didSet {
			self.contentInset = self.requiresInset ? UIEdgeInsets(top: self.safeAreaInsets.top + 80, left: 0, bottom: 40, right: 0) : UIEdgeInsets(top: 20, left: 0, bottom: 40, right: 0)
		}
	}
	
	// MARK: Content View
	private(set) var contentView: UIView!
	
	// MARK: Properties
	private var tubeMap: TubeMap!
	
	// MARK: Animation Properties
	private var loadingAnimationTimer: Timer!
	
	// MARK: - JSON
	// MARK: JSON Structs
	/// The JSON decodable style
	struct DecodedTubeMap: Decodable {
		let canvasMetadata: MapMetadata
		
		let stationNames: [StationName]
		let riverPaths: [MapPath]
		let chevronMarks: [MapPath]
		let stationMarkers: [MapMarker]
		
		let bakerloo: [MapLine]
		let central: [MapLine]
		let circle: [MapLine]
		let district: [MapLine]
		let hammersmithCity: [MapLine]
		let jubilee: [MapLine]
		let metropolitan: [MapLine]
		let northern: [MapLine]
		let piccadilly: [MapLine]
		let victoria: [MapLine]
		let waterlooCity: [MapLine]
		let dlr: [MapLine]
		let tflRail: [MapLine]
		let londonOverground: [MapLine]
	}
	
	/// The map's metadata
	struct MapMetadata: Decodable {
		let width: Int
		let height: Int
	}
	
	/// Represents a path (only used for river paths and chevrons)
	struct MapPath: Decodable {
		let id: String
		let svg: String
		let width: CGFloat
	}
	
	/// Represents a line between two stations
	struct MapLine: Decodable {
		let id: String
		let svg: String
		let line: Stations.Line
		let isNightTube: Bool
		
		// Decodable
		enum CodingKeys: String, CodingKey {
			case id
			case svg
			case isNightTube
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			self.id = try container.decode(String.self, forKey: .id)
			self.svg = try container.decode(String.self, forKey: .svg)
			self.line = Stations.Line(rawValue: id.extract(from: 16))!
			self.isNightTube = try container.decode(Bool.self, forKey: .isNightTube)
		}
	}
	
	/// Represents a station
	struct MapMarker: Decodable {
		let type: MarkerType
		let line: Stations.Line?
		var markers: [MapMarker]?
		var x: CGFloat?
		var y: CGFloat?
		let transforms: MapMarkerTransforms?
		
		var x2: CGFloat?
		var y2: CGFloat?
		
		var category: String?
		var innerConnector: [String]?
		var outerConnector: [String]?
	}
	
	struct MapMarkerTransforms: Decodable {
		let angle: CGFloat
		let offsetX: CGFloat
		let offsetY: CGFloat
	}
	
	enum MarkerType: String, Decodable {
		case terminator
		case dash
		case singleInterchange
		case singleBlueWheelchair
		case singleWhiteWheelchair
		case complexInterchange
		case interchangeConnector
	}
	
	struct StationName: Decodable {
		let text: String
		let x: CGFloat
		let y: CGFloat
		let width: CGFloat
		let height: CGFloat
		let stationIdentifier: Int
	}
	
	// MARK: Parsing Methods
	/// Parse `Tube Map.json`
	/// - parameter completion: Returns `DecodedTubeMap` asynchronously
	func parse(completion: @escaping(DecodedTubeMap) -> Void) {
		guard let stationJSON = Bundle.main.path(forResource: "Tube Map", ofType: "json") else { return }
		guard let data = try? Data(contentsOf: URL(fileURLWithPath: stationJSON), options: []) else { return }
		
		do {
			completion(try JSONDecoder().decode(DecodedTubeMap.self, from: data))
			print("[Map] Parsed Tube Map.json")
		} catch let error {
			print("[Map] Error decoding Tube Map.json: \(error)")
		}
	}
	
	// MARK: - Drawing
	/// The drawable representation of the Tube Map
	struct TubeMap {
		let canvasMetadata: MapMetadata
		
		let stationNames: [Text]
		let riverPaths: [PathBezier]
		let chevronMarks: [PathBezier]
		let stationMarkers: [MarkerBezier]
		
		let bakerloo: [LineBezier]
		let central: [LineBezier]
		let circle: [LineBezier]
		let district: [LineBezier]
		let hammersmithCity: [LineBezier]
		let jubilee: [LineBezier]
		let metropolitan: [LineBezier]
		let northern: [LineBezier]
		let piccadilly: [LineBezier]
		let victoria: [LineBezier]
		let waterlooCity: [LineBezier]
		let dlr: [LineBezier]
		let tflRail: [LineBezier]
		let londonOverground: [LineBezier]
		
		init(from decoded: DecodedTubeMap) {
			self.canvasMetadata = decoded.canvasMetadata
			
			self.riverPaths = decoded.riverPaths.map({PathBezier(information: $0)})
			self.chevronMarks = decoded.chevronMarks.map({PathBezier(information: $0)})
			self.stationMarkers = decoded.stationMarkers.map({MarkerBezier(information: $0)})
			self.stationNames = decoded.stationNames.map({Text(from: $0)})
			
			self.bakerloo = decoded.bakerloo.map({LineBezier(information: $0)})
			self.central = decoded.central.map({LineBezier(information: $0)})
			self.circle = decoded.circle.map({LineBezier(information: $0)})
			self.district = decoded.district.map({LineBezier(information: $0)})
			self.hammersmithCity = decoded.hammersmithCity.map({LineBezier(information: $0)})
			self.jubilee = decoded.jubilee.map({LineBezier(information: $0)})
			self.metropolitan = decoded.metropolitan.map({LineBezier(information: $0)})
			self.northern = decoded.northern.map({LineBezier(information: $0)})
			self.piccadilly = decoded.piccadilly.map({LineBezier(information: $0)})
			self.victoria = decoded.victoria.map({LineBezier(information: $0)})
			self.waterlooCity = decoded.waterlooCity.map({LineBezier(information: $0)})
			self.dlr = decoded.dlr.map({LineBezier(information: $0)})
			self.tflRail = decoded.tflRail.map({LineBezier(information: $0)})
			self.londonOverground = decoded.londonOverground.map({LineBezier(information: $0)})
		}
	}
	
	// MARK: - Drawing Classes
	/// A path drawing class for `MapPath`
	class PathBezier {
		var information: MapPath
		var layer: CAShapeLayer!
		var path: UIBezierPath!
		
		init(information: MapPath) {
			self.information = information
			self.layer = CAShapeLayer()
			self.path = UIBezierPath(pathString: information.svg)
			
			self.layer.lineJoin = .round
			self.layer.fillRule = .evenOdd
			self.layer.lineWidth = information.width
			self.layer.fillColor = nil
			
			self.show()
			
			self.layer.path = self.path.cgPath
		}
		
		/// Make the stroke of the layer visible
		func show() {
			if information.id == "River" {
				self.layer.fillColor = UIColor(named: "River Fill")?.cgColor ?? UIColor.blue.cgColor
			} else if information.id == "North_Bank" || information.id == "South_Bank" {
				self.layer.strokeColor = UIColor(named: "River Bank")?.cgColor ?? UIColor.lightGray.cgColor
			} else if information.id == "Chevron" {
				self.layer.strokeColor = UIColor.white.cgColor
				self.layer.fillColor = UIColor.white.cgColor
			} else {
				self.layer.strokeColor = nil
			}
		}
		
		/// Hide the stroke of the layer
		func hide() {
			if information.id == "River" {
				self.layer.fillColor = UIColor.clear.cgColor
			} else {
				self.layer.strokeColor = UIColor.clear.cgColor
			}
		}
	}
	
	/// A path drawing class for `MapLine`
	class LineBezier {
		var information: MapLine
		var outlineLayer: CAShapeLayer!
		var layer: CAShapeLayer!
		var path: UIBezierPath!
		var innerLayer: CAShapeLayer?
		var innerPath: UIBezierPath?
		
		var activated: Bool
		
		init(information: MapLine) {
			self.information = information
			self.outlineLayer = CAShapeLayer()
			let outlinePath = UIBezierPath(pathString: information.svg)
			
			self.layer = CAShapeLayer()
			self.path = UIBezierPath(pathString: information.svg)
			
			self.layer.name = information.id
			self.layer.strokeColor = UIColor(named: information.line.prettyName())!.cgColor
			self.layer.lineJoin = .round
			self.layer.fillRule = .evenOdd
			self.layer.lineWidth = 2.35
			self.layer.fillColor = nil
			
			self.outlineLayer.strokeColor = UIColor.white.cgColor
			self.outlineLayer.lineJoin = .round
			self.outlineLayer.fillRule = .evenOdd
			self.outlineLayer.lineWidth = 3.0
			self.outlineLayer.fillColor = nil
			
			switch information.line {
			case .dlr, .tflRail, .overground:
				let innerLayer = CAShapeLayer()
				let innerPath = UIBezierPath(pathString: information.svg)
				
				innerLayer.strokeColor = UIColor.white.cgColor
				innerLayer.lineJoin = .round
				innerLayer.lineWidth = 0.83
				innerLayer.fillColor = nil
				
				innerLayer.path = innerPath.cgPath
				
				self.innerLayer = innerLayer
				self.innerPath = innerPath
			default:
				break
			}
			
			self.layer.path = self.path.cgPath
			self.outlineLayer.path = outlinePath.cgPath
			
			self.activated = false
		}
		
		/// Make the line stand out
		func activate() {
			var glowColor: CGColor {
				if self.information.line == .northern {
					return UIColor.white.glow().cgColor
				} else {
					return UIColor(named: self.information.line.prettyName())!.glow().cgColor
				}
			}
			
			UIView.animate(withDuration: 0.4) {
				self.layer.strokeColor = UIColor(named: self.information.line.prettyName())!.cgColor
				self.layer.shadowColor = glowColor
				self.layer.shadowRadius = 4
				self.layer.shadowOpacity = 1
				self.layer.shadowOffset = CGSize(width: 0, height: 1)
				
				self.outlineLayer.strokeColor = UIColor.white.cgColor
			}
			
			if let innerLayer = self.innerLayer {
				innerLayer.strokeColor = UIColor.white.cgColor
			}
			
			self.activated = true
		}
		
		/// Make the line faded/not stand out
		func deactivate() {
			UIView.animate(withDuration: 0.4) {
				self.layer.strokeColor = UIColor(named: self.information.line.prettyName())!.darken().cgColor
				self.layer.shadowColor = nil
				self.layer.shadowRadius = 0
				self.layer.shadowOpacity = 0
				
				self.outlineLayer.strokeColor = UIColor.clear.cgColor
			}
			
			if let innerLayer = self.innerLayer {
				innerLayer.strokeColor = UIColor.white.darken().cgColor
			}
			
			self.activated = false
		}
		
		/// Make the line faded/not stand out.
		/// For use only when night tube is in operation.
		func nightTubeDeactivate() {
			UIView.animate(withDuration: 0.4) {
				self.layer.strokeColor = UIColor.gray.withAlphaComponent(0.3).cgColor
				self.layer.shadowColor = nil
				self.layer.shadowRadius = 0
				self.layer.shadowOpacity = 0
				
				self.outlineLayer.strokeColor = UIColor.darkGray.cgColor
			}
		}
		
		/// Make the line invisible
		func hide() {
			self.deactivate()
			
			self.layer.strokeColor = UIColor.clear.cgColor
			self.layer.shadowColor = UIColor.clear.cgColor
			self.outlineLayer.strokeColor = UIColor.clear.cgColor
			
			if let innerLayer = self.innerLayer {
				innerLayer.strokeColor = UIColor.clear.cgColor
			}
		}
		
	}
	
	/// Drawing class for station dashes, terminators and interchange connectors
	class MarkerBezier {
		var information: MapMarker
		var layer: CAShapeLayer!
		var path: UIBezierPath!
		var innerPath: UIBezierPath?
		
		var layers: [MarkerBezier]?
		
		init(information: MapMarker) {
			self.information = information
			self.layer = CAShapeLayer()
			
			switch self.information.type {
			case .terminator:
				self.drawTerminator()
			case .dash:
				self.drawDash()
			case .singleInterchange:
				self.drawInterchange() {}
			case .singleBlueWheelchair:
				self.drawBlueWheelchair() {}
			case .singleWhiteWheelchair:
				self.drawWhiteWheelchair() {}
			case .complexInterchange:
				self.layers = []
				self.drawComplexInterchange()
			case .interchangeConnector:
				self.drawInterchangeConnector() {}
			}
		}
		
		private func drawTerminator() {
			let startX = information.x! - (5.55 / 2)
			let startY = information.y! - (1.75 / 2)
			
			self.path = UIBezierPath(rect: CGRect(x: startX, y: startY, width: 5.55, height: 1.75))
			self.layer.path = self.path.cgPath
			
			self.layer.strokeColor = UIColor(named: information.line!.prettyName())!.cgColor
			self.layer.lineJoin = .round
			self.layer.fillColor = UIColor(named: information.line!.prettyName())!.cgColor
			
			if let transforms = information.transforms {
				self.layer.transform = CATransform3DMakeRotation((transforms.angle * CGFloat.pi/180), 1.0, 0, 0)
				self.layer.transform = CATransform3DMakeTranslation(transforms.offsetX, transforms.offsetY, 1)
				print("[Map] Transform applied! Rotated \(transforms.angle * CGFloat.pi/180))")
			}
		}
		
		private func drawDash() {
			let startX = information.x!
			let startY = information.y!
			
			self.path = UIBezierPath(rect: CGRect(x: startX, y: startY, width: 1.55, height: 2.75))
			
			self.layer.strokeColor = UIColor(named: information.line!.prettyName())!.cgColor
			self.layer.lineJoin = .round
			self.layer.fillColor = UIColor(named: information.line!.prettyName())!.cgColor
			
			if let transforms = information.transforms {
				// FIXME: How do you perform a rotation transform around point (midX, midY)?
				self.layer.transform = CATransform3DMakeRotation((transforms.angle * CGFloat.pi/180), 1.0, 0, 0)
				self.layer.transform = CATransform3DMakeTranslation(transforms.offsetX, transforms.offsetY, 1)
				print("[Map] Transform applied!")
			}
			
			self.layer.path = self.path.cgPath
		}
		
		private func drawInterchange(completion: @escaping() -> Void) {
			let point = CGPoint(x: self.information.x!, y: self.information.y!)
			
			// Outer circle
			let circle = CAShapeLayer()
			self.path = UIBezierPath(arcCenter: point, radius: 2.5, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
			
			circle.lineWidth = 2.5
			circle.strokeColor = UIColor.black.cgColor
			circle.fillColor = UIColor.black.cgColor
			circle.path = path.cgPath
			
			// Inner Circle
			let innerCircle = CAShapeLayer()
			self.innerPath = UIBezierPath(arcCenter: point, radius: 1.6, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
			
			innerCircle.lineWidth = 1.8
			innerCircle.strokeColor = UIColor.white.cgColor
			innerCircle.fillColor = UIColor.white.cgColor
			innerCircle.path = self.innerPath!.cgPath
			
			// Add to view
			self.layer.addSublayer(circle)
			self.layer.insertSublayer(innerCircle, above: circle)
			
			completion()
		}
		
		private func drawWhiteWheelchair(completion: @escaping() -> Void) {
			let center = CGPoint(x: self.information.x!, y: self.information.y!)
			
			// Border Circle
			let circle = CAShapeLayer()
			self.path = UIBezierPath(arcCenter: center, radius: 2.5, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
			
			circle.lineWidth = 2.5
			circle.strokeColor = UIColor(named: "Blue Wheelchair")!.cgColor
			circle.fillColor = UIColor(named: "Blue Wheelchair")!.cgColor
			circle.path = path.cgPath
			
			// Inner Circle
			let innerCircle = CAShapeLayer()
			self.innerPath = UIBezierPath(arcCenter: center, radius: 2.1, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
			
			innerCircle.lineWidth = 2.2
			innerCircle.strokeColor = UIColor.white.cgColor
			innerCircle.fillColor = UIColor.white.cgColor
			innerCircle.path = self.innerPath!.cgPath
			
			// Add to view
			self.layer.addSublayer(circle)
			self.layer.insertSublayer(innerCircle, above: circle)
			
			// Wheelchair
			self.drawWheelchair(color: UIColor(named: "Blue Wheelchair")!.cgColor, point: center)
			
			completion()
		}
		
		private func drawBlueWheelchair(completion: @escaping() -> Void) {
			let center = CGPoint(x: self.information.x!, y: self.information.y!)
			
			// Circle
			let circle = CAShapeLayer()
			self.path = UIBezierPath(arcCenter: center, radius: 2.5, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
			
			circle.lineWidth = 2.5
			circle.strokeColor = UIColor(named: "Blue Wheelchair")!.cgColor
			circle.fillColor = UIColor(named: "Blue Wheelchair")!.cgColor
			circle.path = path.cgPath
			
			// Add to view
			self.layer.addSublayer(circle)
			
			// Wheelchair
			self.drawWheelchair(color: UIColor.white.cgColor, point: center)
			
			completion()
		}
		
		private func drawWheelchair(color: CGColor, point: CGPoint) {
			// Head
			let head = CAShapeLayer()
			let headPoint = CGPoint(x: point.x + 0.4, y: point.y - 2.4)
			let headPath = UIBezierPath(arcCenter: headPoint, radius: 0.4, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
			
			head.lineWidth = 0.4
			head.strokeColor = color
			head.fillColor = color
			head.path = headPath.cgPath
			
			// Body
			let body = CAShapeLayer()
			let bodyPath = UIBezierPath(pathString: "M 1.65,-0.78 L 1.6,-0.41 0.47,-0.41 C 0.47,-0.41 0.24,-0.39 0.24,-0.16 0.24,0.06 0.47,0.09 0.47,0.09 L 1.53,0.09 1.48,0.44 0.05,0.44 C 0.05,0.44 -0.05,0.44 -0.1,0.49 -0.14,0.53 -0.19,0.64 -0.19,0.64 L -0.98,2.26 C -0.98,2.26 -1.07,2.47 -0.84,2.59 -0.62,2.71 -0.47,2.48 -0.47,2.48 L 0.15,1.2 C 0.15,1.2 0.21,1.11 0.26,1.09 0.34,1.05 0.39,1.05 0.39,1.05 L 1.7,1.05 C 1.7,1.05 1.83,1.05 1.94,0.94 2.05,0.84 2.07,0.72 2.07,0.72 L 2.27,-0.69 C 2.27,-0.69 2.26,-0.98 1.96,-1 1.73,-1.02 1.65,-0.78 1.65,-0.78 Z M 1.65,-0.78")
			
			body.lineWidth = 0.15
			body.strokeColor = color
			body.fillColor = color
			body.path = bodyPath.cgPath
			body.transform = CATransform3DMakeTranslation(point.x - 1.5, point.y - 0.5, 1)
			
			// Wheels
			let wheels = CAShapeLayer()
			let wheelsPath = UIBezierPath(pathString: "M 0.29,1.96 C 0.46,2.51 0.97,2.91 1.58,2.91 2.32,2.91 2.92,2.31 2.92,1.57 2.92,1.18 2.75,0.83 2.49,0.58 L 2.57,-0 C 3.09,0.33 3.43,0.91 3.43,1.57 3.43,2.6 2.6,3.43 1.58,3.43 0.91,3.43 0.33,3.08 0,2.55 L 0.29,1.96 Z M 0.29,1.96")
			
			wheels.lineWidth = 0.15
			wheels.strokeColor = color
			wheels.fillColor = color
			wheels.path = wheelsPath.cgPath
			wheels.transform = CATransform3DMakeTranslation(point.x - 1.5, point.y - 0.5, 1)
			
			self.layer.addSublayer(head)
			self.layer.addSublayer(body)
			self.layer.addSublayer(wheels)
		}
		
		// TODO: Refactor by extracting the category business into separate methods
		/// Draws a complex interchange type
		private func drawComplexInterchange() {
			// For category A, draw inner first, then outer
			// For category B, draw outer first, then inner
			
			if self.information.category! == "A" {
				// First draw inner connectors
				for connector in self.information.innerConnector! {
					let layer = CAShapeLayer()
					let path = UIBezierPath(pathString: connector)
					
					layer.lineWidth = 0.4
					layer.strokeColor = UIColor.white.cgColor
					layer.fillColor = UIColor.white.cgColor
					layer.path = path.cgPath
					
					self.layer.addSublayer(layer)
				}
				
				// Then draw outer connectors
				for connector in self.information.outerConnector! {
					let layer = CAShapeLayer()
					let path = UIBezierPath(pathString: connector)
					
					layer.lineWidth = 0.2
					layer.strokeColor = UIColor.black.cgColor
					layer.path = path.cgPath
					
					self.layer.addSublayer(layer)
				}
			} else if self.information.category! == "B" {
				// First draw outer connectors
				for connector in self.information.outerConnector! {
					let layer = CAShapeLayer()
					let path = UIBezierPath(pathString: connector)
					
					layer.lineWidth = 0.2
					layer.strokeColor = UIColor.black.cgColor
					layer.path = path.cgPath
					
					self.layer.addSublayer(layer)
				}
				
				// Then draw singleInterchange markers
				for marker in self.information.markers!.filter({$0.type == .singleInterchange}) {
					self.information.x = marker.x
					self.information.y = marker.y
					
					self.drawInterchange {
						self.information.x = nil
						self.information.y = nil
					}
				}
				
				self.information.markers!.removeAll(where: {$0.type == .singleInterchange})
				
				// Next draw inner connectors
				for connector in self.information.innerConnector! {
					let layer = CAShapeLayer()
					let path = UIBezierPath(pathString: connector)
					
					layer.lineWidth = 0.2
					layer.strokeColor = UIColor.white.cgColor
					layer.fillColor = UIColor.white.cgColor
					layer.path = path.cgPath
					
					self.layer.addSublayer(layer)
				}
			}
			
			// Finally, draw markers
			let drawingInstructions = self.information.markers!
			for marker in drawingInstructions {
				switch marker.type {
				case .singleInterchange:
					self.information.x = marker.x
					self.information.y = marker.y
					
					self.drawInterchange {
						self.information.x = nil
						self.information.y = nil
					}
				case .singleBlueWheelchair:
					self.information.x = marker.x
					self.information.y = marker.y
					
					self.drawBlueWheelchair {
						self.information.x = nil
						self.information.y = nil
					}
				case .singleWhiteWheelchair:
					self.information.x = marker.x
					self.information.y = marker.y
					
					self.drawWhiteWheelchair {
						self.information.x = nil
						self.information.y = nil
					}
				case .interchangeConnector:
					self.information.x = marker.x
					self.information.y = marker.y
					self.information.x2 = marker.x2
					self.information.y2 = marker.y2
					
					self.drawInterchangeConnector {
						self.information.x = nil
						self.information.y = nil
						self.information.x2 = nil
						self.information.y2 = nil
					}
				default:
					continue
				}
			}
		}
		
		private func drawInterchangeConnector(completion: @escaping() -> Void) {
			// Draw backing to interchange connector
			let backgroundLayer = CAShapeLayer()
			let backgroundPath = UIBezierPath()
			
			guard let x = self.information.x else { return }
			guard let y = self.information.y else { return }
			guard let x2 = self.information.x2 else { return }
			guard let y2 = self.information.y2 else { return }
			
			backgroundPath.move(to: CGPoint(x: x, y: y))
			backgroundPath.move(to: CGPoint(x: x2, y: y2))
			
			backgroundLayer.lineWidth = 3.6
			backgroundLayer.strokeColor = UIColor.black.cgColor
			backgroundLayer.fillColor = UIColor.black.cgColor
			backgroundLayer.path = backgroundPath.cgPath
			
			// Draw white connector between interchange connectors
			let foregroundLayer = CAShapeLayer()
			let foregroundPath = UIBezierPath()
			
			foregroundPath.move(to: CGPoint(x: x, y: y))
			foregroundPath.move(to: CGPoint(x: x2, y: y2))
			
			foregroundLayer.lineWidth = 2.0
			foregroundLayer.strokeColor = UIColor.white.cgColor
			foregroundLayer.fillColor = UIColor.white.cgColor
			foregroundLayer.path = foregroundPath.cgPath
			
			// Add paths to view
			self.layer.addSublayer(backgroundLayer)
			self.layer.insertSublayer(foregroundLayer, above: backgroundLayer)
			
			completion()
		}
	}
	
	class Text {
		let text: String
		let x: CGFloat
		let y: CGFloat
		let width: CGFloat
		let height: CGFloat
		let textSize: CGFloat
		let stationIdentifier: Int
		
		var layer: CATextLayer!
		
		init(from data: StationName) {
			self.text = data.text
			self.x = data.x
			self.y = data.y
			self.width = data.width
			self.height = data.height
			self.textSize = 4.5
			self.stationIdentifier = data.stationIdentifier
		}
		
		func addLabel() -> CATextLayer {
			self.layer = CATextLayer()
			
			self.layer.frame = CGRect(x: self.x, y: self.y, width: self.width * 3, height: self.height * 3)
			self.layer.font = UIFont(name: "Railway", size: 4.5)
			self.layer.fontSize = 4.5
			self.layer.contentsScale = UIScreen.main.scale * 7
			self.layer.alignmentMode = .left
			self.layer.string = self.text.capitalized
			self.layer.backgroundColor = UIColor.clear.cgColor
			self.layer.foregroundColor = UIColor.white.cgColor
			
			return self.layer
		}
		
		func hide() {
			self.layer.foregroundColor = UIColor.clear.cgColor
		}
		
		func show() {
			self.layer.foregroundColor = UIColor.white.cgColor
		}
	}
	
	// MARK: Drawing Methods
	func setupMap(completion: @escaping() -> Void) {
		// Parse 'Tube Map.json' file
		self.parse { (decodedTubeMap) in
			// Setup content view
			self.contentView = UIView(frame: CGRect(x: 0, y: 0, width: decodedTubeMap.canvasMetadata.width, height: decodedTubeMap.canvasMetadata.height))
			self.addSubview(self.contentView)
			self.tubeMap = TubeMap(from: decodedTubeMap)
			
			// Setup scroll view
			self.isScrollEnabled = true
			self.contentSize = CGSize(width: decodedTubeMap.canvasMetadata.width, height: decodedTubeMap.canvasMetadata.height)
			self.setZoomScale(1.4, animated: false)
			self.setContentOffset(CGPoint(x: (decodedTubeMap.canvasMetadata.width / 2), y: (decodedTubeMap.canvasMetadata.height / 2)), animated: false)
			
			// Draw the map
			if Date().isNightTube() {
				self.drawNightTubeMap() {
					completion()
				}
			} else {
				self.drawMap() {
					self.deactivateAllLayers {
						completion()
					}
				}
			}
		}
	}
	
	func reset() {
		self.deactivateAllLayers { }
	}
	
	/// Draw the tube map on the content view
	private func drawMap(completion: () -> Void) {
		// Clear all drawn content
		self.contentView.layer.sublayers?.removeAll()
		
		// Layer order:
		//  1. River
		self.tubeMap.riverPaths.forEach({self.addLayer($0.layer)})
		
		//  2. Waterloo & City
		self.tubeMap.waterlooCity.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		//  3. TfL Rail
		self.tubeMap.tflRail.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer); self.addLayer($0.innerLayer!)})
		
		//  4. London Overground
		self.tubeMap.londonOverground.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer); self.addLayer($0.innerLayer!)})
		
		//  5. DLR
		self.tubeMap.dlr.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer); self.addLayer($0.innerLayer!)})
		
		//  6. Bakerloo
		self.tubeMap.bakerloo.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		//  7. Jubilee
		self.tubeMap.jubilee.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		//  8. Victoria
		self.tubeMap.victoria.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		//  9. Northern
		self.tubeMap.northern.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		// 10. Piccadilly
		self.tubeMap.piccadilly.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		// 11. Central
		self.tubeMap.central.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		// 12. Hammersmith & City
		self.tubeMap.hammersmithCity.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		// 13. Circle
		self.tubeMap.circle.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		// 14. District
		self.tubeMap.district.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		// 15. Metropolitan
		self.tubeMap.metropolitan.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		// 16. Waterloo & City
		self.tubeMap.waterlooCity.forEach({self.addLayer($0.outlineLayer); self.addLayer($0.layer)})
		
		// 17. Chevron Direction Marks
		self.tubeMap.chevronMarks.forEach({self.addLayer($0.layer)})
		
		// 18. Interchange Connectors & Station Indicators
		self.tubeMap.stationMarkers.forEach({self.addLayer($0.layer)})
		
		// 19. Station Names
		self.tubeMap.stationNames.forEach({self.addLabel($0.addLabel())})
		
		completion()
	}
	
	/// Draw the night tube map on the content view
	func drawNightTubeMap(completion: () -> Void) {
		// Night Tube Services:
		// • Jubilee (All)
		// • Victoria (All)
		// • Northern (Edgware, High Barnet <– Charing Cross Branch –> Morden)
		// • Piccadilly (Cockfosters <––> Heathrow T5 (No T4))
		// • Central (Loughton, Hainault <––> Ealing Broadway)
		// • London Overground (Highbury & Islington <––> New Cross Gate)
		
		// Draw normal tube map
		self.drawMap() {
			// Dim non-night tube lines
			self.tubeMap.bakerloo.forEach({$0.nightTubeDeactivate()})
			self.tubeMap.circle.forEach({$0.nightTubeDeactivate()})
			self.tubeMap.district.forEach({$0.nightTubeDeactivate()})
			self.tubeMap.hammersmithCity.forEach({$0.nightTubeDeactivate()})
			self.tubeMap.metropolitan.forEach({$0.nightTubeDeactivate()})
			self.tubeMap.tflRail.forEach({$0.nightTubeDeactivate()})
			self.tubeMap.dlr.forEach({$0.nightTubeDeactivate()})
			self.tubeMap.waterlooCity.forEach({$0.nightTubeDeactivate()})
			
			// Dim non-night tube sections
			self.tubeMap.northern.filter({!$0.information.isNightTube}).forEach({$0.nightTubeDeactivate()})
			self.tubeMap.piccadilly.filter({!$0.information.isNightTube}).forEach({$0.nightTubeDeactivate()})
			self.tubeMap.central.filter({!$0.information.isNightTube}).forEach({$0.nightTubeDeactivate()})
			self.tubeMap.londonOverground.filter({!$0.information.isNightTube}).forEach({$0.nightTubeDeactivate()})
			
			self.tubeMap.jubilee.forEach({$0.deactivate()})
			self.tubeMap.victoria.forEach({$0.deactivate()})
			self.tubeMap.northern.filter({$0.information.isNightTube}).forEach({$0.deactivate()})
			self.tubeMap.piccadilly.filter({$0.information.isNightTube}).forEach({$0.deactivate()})
			self.tubeMap.central.filter({$0.information.isNightTube}).forEach({$0.deactivate()})
			self.tubeMap.londonOverground.filter({$0.information.isNightTube}).forEach({$0.deactivate()})
			
			completion()
		}
	}
	
	/// Add a layer into the content view
	/// - parameter layer: The layer to add to the content view
	private func addLayer(_ layer: CAShapeLayer) {
		self.contentView.layer.addSublayer(layer)
	}
	
	/// Add a text lavel layer into the content view
	/// - parameter layer: The layer to add to the content view
	private func addLabel(_ label: CATextLayer) {
		self.contentView.layer.addSublayer(label)
	}
	
	// MARK: Map Routing Methods
	/// Show the route on the map
	/// - parameter data: The human representation of the route
	func showRoute(_ data: Routing.Route) {
		let instructions = data.instructions.filter({$0.type == .route})
		
		self.deactivateAllLayers {
			// Highlight Route
			for instruction in instructions {
				for (index, station) in instruction.stations!.enumerated() {
					if index == instruction.stations!.count - 1 { break }
					
					// Match Bezier
					guard let matchingBezier = self.findBezier(from: station.ic, to: instruction.stations![index + 1].ic, line: instruction.line!) else { continue }
					
					// Activate Bezier
					matchingBezier.activate()
				}
			}

			// Show Station Names
			for station in data.stations {
				self.findStationLabels(using: station.ic).forEach({$0.show()})
			}
		}
	}
	
	/// Find a path between two stations on a `Stations.Line`
	/// - parameter from: The from station's identifier code
	/// - parameter to: The to station's identifier code
	/// - parameter line: The tube line the bezier will be on
	/// - returns: The line bezier between `from` and `to` on the specified `line`.
	func findBezier(from: Int, to: Int, line: Stations.Line) -> LineBezier? {
		var searchText: String {
			if from < to {
				return "\(from)_\(to)_\(line.rawValue)"
			} else {
				return "\(to)_\(from)_\(line.rawValue)"
			}
		}
		
//		print("[Map] Matching bezier \(searchText)")
		
		switch line {
		case .bakerloo:
			return self.tubeMap.bakerloo.first(where: {$0.information.id == searchText})
		case .central:
			return self.tubeMap.central.first(where: {$0.information.id == searchText})
		case .circle:
			return self.tubeMap.circle.first(where: {$0.information.id == searchText})
		case .district:
			return self.tubeMap.district.first(where: {$0.information.id == searchText})
		case .hammersmithCity:
			return self.tubeMap.hammersmithCity.first(where: {$0.information.id == searchText})
		case .jubilee:
			return self.tubeMap.jubilee.first(where: {$0.information.id == searchText})
		case .metropolitan:
			return self.tubeMap.metropolitan.first(where: {$0.information.id == searchText})
		case .northern:
			return self.tubeMap.northern.first(where: {$0.information.id == searchText})
		case .piccadilly:
			return self.tubeMap.piccadilly.first(where: {$0.information.id == searchText})
		case .victoria:
			return self.tubeMap.victoria.first(where: {$0.information.id == searchText})
		case .waterlooCity:
			return self.tubeMap.waterlooCity.first(where: {$0.information.id == searchText})
		case .dlr:
			return self.tubeMap.dlr.first(where: {$0.information.id == searchText})
		case .overground:
			return self.tubeMap.londonOverground.first(where: {$0.information.id == searchText})
		case .tflRail:
			return self.tubeMap.tflRail.first(where: {$0.information.id == searchText})
		default:
			return nil
		}
	}
	
	func findStationLabels(using identifier: Int) -> [Text] {
		return self.tubeMap.stationNames.filter({$0.stationIdentifier == identifier})
	}
	
	// MARK: Map Animation Methods
	// Deactivates all layers with a duration of 0.2 seconds and a delay of 0.1 seconds
	private func deactivateAllLayers(completion: @escaping() -> Void) {
		UIView.animate(withDuration: 0.2, delay: 0.1, animations: {
			//  2. TfL Rail
			self.tubeMap.tflRail.forEach({$0.deactivate()})
			
			//  3. London Overground
			self.tubeMap.londonOverground.forEach({$0.deactivate()})
			
			//  4. DLR
			self.tubeMap.dlr.forEach({$0.deactivate()})
			
			//  5. Waterloo & City
			self.tubeMap.waterlooCity.forEach({$0.deactivate()})
			
			//  6. Bakerloo
			self.tubeMap.bakerloo.forEach({$0.deactivate()})
			
			//  7. Jubilee
			self.tubeMap.jubilee.forEach({$0.deactivate()})
			
			//  8. Victoria
			self.tubeMap.victoria.forEach({$0.deactivate()})
			
			//  9. Northern
			self.tubeMap.northern.forEach({$0.deactivate()})
			
			// 10. Piccadilly
			self.tubeMap.piccadilly.forEach({$0.deactivate()})
			
			// 11. Central
			self.tubeMap.central.forEach({$0.deactivate()})
			
			// 12. Hammersmith & City
			self.tubeMap.hammersmithCity.forEach({$0.deactivate()})
			
			// 13. Circle
			self.tubeMap.circle.forEach({$0.deactivate()})
			
			// 14. District
			self.tubeMap.district.forEach({$0.deactivate()})
			
			// 15. Metropolitan
			self.tubeMap.metropolitan.forEach({$0.deactivate()})
			
			// 16. Waterloo & City
			self.tubeMap.waterlooCity.forEach({$0.deactivate()})
			
			// 17. Chevron Direction Marks
			self.tubeMap.chevronMarks.forEach({$0.hide()})
			
			// 18. Station Names
			self.tubeMap.stationNames.forEach({$0.hide()})
			
			self.contentView.layer.setNeedsLayout()
			self.contentView.layer.layoutIfNeeded()
		}) { (_) in
			completion()
		}
	}
	
	// MARK: Focus Methods
	/// Tells the view to focus on the coordinates where the `station` can be found
	/// - parameter station: The station of interest
	func focus(on station: Stations.Station) {
		let visibleRect = CGRect(origin: CGPoint(x: station.mapX, y: station.mapY), size: CGSize(width: 8, height: 8))
		
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
				self.zoom(to: visibleRect, animated: true)
			})
		}
	}
	
	/// Tells the view to focus on the route in the instruction
	/// Takes the map coordinates of the stations and makes them visible in the frame
	/// - parameter instruction: The instruction from which the stations should be retrieved from
	func showPath(from instruction: Routing.Instruction) {
		guard let fromStation = instruction.stations?.first else { return }
		guard let toStation = instruction.stations?.last else { return }
		
		let minX = min(fromStation.mapX, toStation.mapX)
		let minY = min(fromStation.mapY, toStation.mapY)
		let maxX = max(fromStation.mapX, toStation.mapX)
		let maxY = max(fromStation.mapY, toStation.mapY)
		
		let width = 40 + (maxX - minX)
		let height = 40 + (maxY - minY)
		
		let visibleRect = CGRect(x: minX - 20, y: minY - 20, width: width, height: height)
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
				self.zoom(to: visibleRect, animated: true)
			})
		}
	}
	
	func focusOnStations(from: Stations.Station, to: Stations.Station) {
		self.highlightOverview(from: Routing.Route(from: from, to: to, journeyTime: 0, stations: [from, to], instructions: []))
	}
	
	func highlightOverview(from route: Routing.Route) {
		print(" >>> Stations: \(route.stations.map({$0.name}))")
		print(" >>> MinX: \(route.stations.min(by: {$0.mapX < $1.mapX})!.name) -- MinY: \(route.stations.max(by: {$0.mapX < $1.mapX})!.name)")
		print(" >>> MaxY: \(route.stations.min(by: {$0.mapY < $1.mapY})!.name) -- MaxY: \(route.stations.max(by: {$0.mapY < $1.mapY})!.name)")
		
		guard let minX = route.stations.min(by: {$0.mapX < $1.mapX})?.mapX else { return }
		guard let maxX = route.stations.max(by: {$0.mapX < $1.mapX})?.mapX else { return }
		guard let minY = route.stations.min(by: {$0.mapY < $1.mapY})?.mapY else { return }
		guard let maxY = route.stations.max(by: {$0.mapY < $1.mapY})?.mapY else { return }

		let width = (maxX - minX) + 40
		let height = (maxY - minY) + 40 + 150
		
		let visibleRect = CGRect(x: minX - 20, y: minY - 20, width: width, height: height)
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
				self.zoom(to: visibleRect, animated: true)
			})
		}
	}
	
}
