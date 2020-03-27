//
//  StatusDetailViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 30/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class StatusDetailViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var statusDisplayTypeLabel: UILabel!
	@IBOutlet weak private var statusDetailCollection: UICollectionView!
	@IBOutlet weak private var pageIndicator: UIPageControl!
	
	// MARK: Properties
	var status: Status.LineStatus!

	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
        super.viewDidLoad()
		// Do any additional setup after loading the view.
		
		self.setupView()
    }
	
	// MARK: Methods
	/// Sets up the view
	private func setupView() {
		self.statusDisplayTypeLabel.text = "Current Status"
		
		if let lineColor = UIColor(named: status.line.prettyName()) {
			self.view.backgroundColor = lineColor.withAlphaComponent(0.2)
		}
		
		print("[StatusDetailVC] Current: \(status.currentStatusDetails) Future: \(status.futureStatusDetails)")
	}
	
	/**
	Calculates the cell height
	
	- parameter text: The containing text of the label inside the cell
	- parameter font: The font (style and size) used for the text
	- parameter width: The guaranteed width of the cell
	- returns: The height of the cell as a `CGFloat`
	*/
	private func calculateCellHeight(for text: String, font: UIFont, with width: CGFloat) -> CGFloat {
		let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
		
		label.numberOfLines = 100
		label.lineBreakMode = .byWordWrapping
		label.textAlignment = .center
		label.font = font
		label.clipsToBounds = true
		label.text = text
		label.sizeToFit()
		
		return label.frame.height + 40
	}
	
	// MARK: IBActions
	@IBAction private func dismissTapped(_ sender: UIButton) {
		self.dismiss(animated: true, completion: nil)
	}
	
}

// MARK: UICollectionView
extension StatusDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if section == 0 {
			print("[StatusDetailVC] \(status.currentStatusDetails.count) current statuses")
			return status.currentStatusDetails.count
		} else if section == 1 {
			print("[StatusDetailVC] \(status.futureStatusDetails.count) future statuses")
			return status.futureStatusDetails.count
		} else {
			return 0
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let width: CGFloat = UIScreen.main.bounds.width - 40
		var height: CGFloat = 80.0
		guard let font = UIFont(name: "Railway", size: 17.0) else { return CGSize(width: width, height: height) }

		var data: Status.StatusInformation {
			if indexPath.section == 0 {
				// Current status
				return status.currentStatusDetails[indexPath.item]
			} else {
				// Future Status
				return status.futureStatusDetails[indexPath.item]
			}
		}
		
		// Determines whether it is a current or future status
		if status.currentStatusDetails.contains(data) {
			// Current status
			if data.severity == .goodService {
				switch status.line {
				case .overground, .dlr, .tflRail:
					height += self.calculateCellHeight(for: "There is currently a good service on all routes.", font: font, with: width - 24)
				default:
					height += self.calculateCellHeight(for: "There is currently a good service.", font: font, with: width - 24)
				}
			} else {
				if let information = data.information {
					height += self.calculateCellHeight(for: information, font: font, with: width - 24)
				}
			}
		} else {
			// Future Status
			if data.severity == .goodService {
				height += self.calculateCellHeight(for: "There are no planned closures in the next seven days.", font: font, with: width - 24)
			} else {
				if let information = data.information {
					height += self.calculateCellHeight(for: information, font: font, with: width - 24) + 30
				}
			}
		}
		
		return CGSize(width: width, height: height)
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Status Details", for: indexPath) as! DetailedStatusCell
		
		var isCurrentStatus: Bool = false
		var data: Status.StatusInformation {
			if indexPath.section == 0 {
				isCurrentStatus = true
				return self.status.currentStatusDetails[indexPath.item]
			} else {
				return self.status.futureStatusDetails[indexPath.item]
			}
		}
		
		cell.setupCell(from: data, forLine: self.status.line, isCurrentStatus: isCurrentStatus)
		
		return cell
	}
	
	// MARK: Page Indicator
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if let collectionView = scrollView as? UICollectionView, let section = collectionView.indexPathsForVisibleItems.first?.section {
			self.pageIndicator.currentPage = section
			
			UIView.animate(withDuration: 0.4) {
				if section == 0 {
					self.statusDisplayTypeLabel.text = "Current Status"
				} else if section == 1 {
					self.statusDisplayTypeLabel.text = "Future Status"
				} 
			}
		}
	}
	
}
