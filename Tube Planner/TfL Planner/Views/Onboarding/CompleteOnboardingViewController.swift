//
//  CompleteOnboardingViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 15/11/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class CompleteOnboardingViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var titleLabel: UILabel!
	@IBOutlet weak private var finishButton: RoundButton!

    // MARK: IBAction
	/// User requested to finish onboarding.
	@IBAction private func finishTapped(_ sender: UIButton) {
		Settings().userHasOnboarded()
		self.finishButton.isEnabled = false

		UIView.animate(withDuration: 0.4, animations: {
			self.finishButton.alpha = 0
		}) { (_) in
			UIView.animate(withDuration: 0.4, delay: 0.3, options: .curveEaseOut, animations: {
				self.titleLabel.alpha = 0
			}, completion: { (_) in
				self.performSegue(withIdentifier: "Segue To Main Storyboard", sender: self)
			})
		}
	}

}
