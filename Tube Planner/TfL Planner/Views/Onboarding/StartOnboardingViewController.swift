//
//  StartOnboardingViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 12/10/2019.
//  Copyright © 2019 g30r93g. All rights reserved.o
//

import UIKit

class StartOnboardingViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var helpText: UILabel!
	@IBOutlet weak private var continueButton: RoundButton!
	@IBOutlet weak private var privacyPolicy: UIButton!
	@IBOutlet weak private var privacyPolicyAgree: RoundButton!
	
	// MARK: Properties
	/// Indicates whether user has agreed to the privacy policy
	var hasAgreedToPrivacyPolicy: Bool = false
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.setupView()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.showHelpText()
	}
	
	// MARK: Methods
	/// Sets up the view
	private func setupView() {
		self.helpText.alpha = 0
		self.continueButton.alpha = 0
		self.privacyPolicy.alpha = 0
		self.privacyPolicyAgree.alpha = 0
		self.continueButton.isUserInteractionEnabled = false
	}
	
	/// Unhides the help text
	private func showHelpText() {
		UIView.animate(withDuration: 0.45, delay: 0.75, options: .curveEaseInOut, animations: {
			self.helpText.alpha = 1
			self.privacyPolicy.alpha = 1
			self.privacyPolicyAgree.alpha = 1
		}) { (_) in
			UIView.animate(withDuration: 0.5, delay: 0.15, options: .curveEaseInOut, animations: {
				self.continueButton.alpha = 0.5
			})
		}
	}
	
	/// Occurs when user taps `privacyPolicyAgree` button
	/// Updates the view for when the privacy policy is agreed with.
	private func updateAgreementStatus() {
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
			self.continueButton.isUserInteractionEnabled = self.hasAgreedToPrivacyPolicy
			self.continueButton.alpha = self.hasAgreedToPrivacyPolicy ? 1 : 0.5
			self.privacyPolicyAgree.borderColor = (self.hasAgreedToPrivacyPolicy ? .clear : (UIColor(named: "Accent 2") ?? .clear))
			self.privacyPolicyAgree.backgroundColor = (self.hasAgreedToPrivacyPolicy ? (UIColor(named: "Accent 3") ?? .clear) : .clear)
		})
	}
	
	// MARK: IBActions
	/// Shows privacy policy to user when `privacyPolicy` is tapped on.
	@IBAction private func showPrivacyPolicy(_ sender: UIButton) {
		let alert = UIAlertController(title: "Privacy Policy\n\n\n\n\n\n\n\n\n\n\n\n", message: "", preferredStyle: .alert)
		
		// Add Privacy Policy as a scrollable text label
		let text = UITextView(frame: CGRect(x: 8.0, y: 50.0, width: 260, height: 250.0))
		
		text.allowsEditingTextAttributes = false
		text.isEditable = false
		text.isSelectable = false
		text.clipsToBounds = true
		text.showsVerticalScrollIndicator = false
		text.showsHorizontalScrollIndicator = false
		text.backgroundColor = UIColor.white.withAlphaComponent(0)
		text.text = Settings().privacyPolicy
		
		alert.view.addSubview(text)
		alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
		
		present(alert, animated: true, completion: nil)
	}
	
	@IBAction private func didChangePrivacyPolicyAgreement(_ sender: UIButton) {
		self.hasAgreedToPrivacyPolicy = !self.hasAgreedToPrivacyPolicy
		
		self.updateAgreementStatus()
	}
	
}
