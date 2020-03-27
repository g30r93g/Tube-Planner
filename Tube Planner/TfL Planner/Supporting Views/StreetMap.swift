//
//  StreetMap.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 06/12/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import MapKit

class StreetMap: MKMapView {
	
	// MARK: Properties
	var polyline: MKPolyline?
	
	// MARK: View Lifecycle
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.delegate = self
	}
	
	// MARK: Methods
	/// Shows walking directions between ```from``` and ```to```.
	public func showWalkingDirections(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, originName: String, destinationName: String) {
		self.reset()
		
		let directionsRequest = MKDirections.Request()
		
		directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: from, addressDictionary: nil))
		directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: to, addressDictionary: nil))
		directionsRequest.requestsAlternateRoutes = false
		directionsRequest.transportType = .walking
		
		let directions = MKDirections(request: directionsRequest)
		
		// Calculate the direction instructions
		directions.calculate { (response, error) in
			guard let response = response else { return }
			if error != nil { return }
			
			// Draw destination pin at end location
			self.drawPin(at: from, annotationName: originName)
			self.drawPin(at: to, annotationName: destinationName)
			
			// Get the polyline for the directions
			guard let route = response.routes.first else { return }
			
			// Apply the polyline to the view
			self.addOverlay(route.polyline, level: .aboveRoads)
			self.polyline = route.polyline
			
			let visibleRect = MKMapRect(x: route.polyline.boundingMapRect.minX - 40, y: route.polyline.boundingMapRect.minY - 40, width: route.polyline.boundingMapRect.width + 80, height: route.polyline.boundingMapRect.height + 80)
			
			// Fit polyline to map view
			self.setVisibleMapRect(visibleRect, animated: true)
		}
	}
	
	/// Draws a pin at ```coordinate``` with the text passed to ```annotationName```.
	private func drawPin(at coordinate: CLLocationCoordinate2D, annotationName: String) {
		let annotation = MKPointAnnotation()
		
		if annotationName == "Current Location" {
			annotation.title = "Start"
		} else {
			annotation.title = annotationName
		}
		
		annotation.coordinate = coordinate
		
		self.showAnnotations([annotation], animated: false)
	}
	
	private func reset() {
		guard let visiblePolyline = self.polyline else { return }
		self.removeOverlay(visiblePolyline)
		self.removeAnnotations(self.annotations)
		self.polyline = nil
	}
	
}

extension StreetMap: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
		
		renderer.strokeColor = UIColor(named: "Accent 1")?.withAlphaComponent(0.5) ?? .white
		renderer.lineWidth = 5
		
		return renderer
	}
	
}
