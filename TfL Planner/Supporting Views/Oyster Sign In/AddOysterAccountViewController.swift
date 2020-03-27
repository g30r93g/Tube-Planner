//
//  AddOysterAccountViewController.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 15/11/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

class AddOysterAccountViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var dismissButton: UIButton!
	@IBOutlet weak private var emailField: BorderedTextField!
	@IBOutlet weak private var passwordField: BorderedTextField!
	@IBOutlet weak private var loadingIndicator: UIActivityIndicatorView!
	
	// MARK: Properties
	var isUpdatingDetails: Bool = false
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.emailField.text = Settings().oysterUsername
	}
	
	// MARK: Methods
	/// Checks user's account and proceeds to complete onboarding.
	private func proceed() {
		self.startLoading()
		
		// Get email and password
		guard let email = self.emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { finishOnboarding(); return }
		guard let password = self.passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { finishOnboarding(); return }
		
		// Ask user to complete all fields
		if (email == "") || (password == "") {
			self.alertUserError(with: "Please complete all fields.")
			self.stopLoading()
			return
		}
		
		// Save and check if user can connect to oyster
		Settings().changeOysterUsername(to: email)
		Settings().changeOysterPassword(to: password)
		
		// Validate Oyster account
		Oyster.account.validateOysterAccount { (isValid) in
			if isValid {
				let alert = UIAlertController(title: "Account Validated", message: "This oyster account will be used for Oyster related features", preferredStyle: .alert)
				
				alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
					self.continueToCardSelection()
				}))
				
				DispatchQueue.main.async {
					self.present(alert, animated: true, completion: nil)
				}
			} else {
				self.alertUserError(with: "Please check your account details.")
			}
		}
	}
	
	/**
	Alert user that an error occurred
		
	- Parameter message: The error message to display to user.
	*/
	private func alertUserError(with message: String) {
		self.stopLoading()
		
		let alert = UIAlertController(title: message, message: "", preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "Ok", style: .default))
		
		DispatchQueue.main.async {
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	/// Confirm the user doesn't want to add an oyster account.
	private func confirmOysterAccount() {
		self.stopLoading()
		
		let alert = UIAlertController(title: "Continue without Oyster Account", message: "Are you sure you don't want to sign into your oyster account? You can always sign in later.", preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "No", style: .destructive))
		alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in self.finishOnboarding() }))
		
		DispatchQueue.main.async {
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	/// Opens the TfL Oyster and Contactless sign up page
	private func signUp() {
		UIApplication.shared.open(URL(string: "https://oyster.tfl.gov.uk/oyster/link/0004.do")!, options: [:], completionHandler: nil)
	}
	
	/// Asks the user whether they definitely wish to continue without an oyster account
	private func skip() {
		self.confirmOysterAccount()
	}
	
	/// Complete onboarding
	private func finishOnboarding() {
		self.stopLoading()
		
		DispatchQueue.main.async {
			self.performSegue(withIdentifier: "Complete Onboarding", sender: self)
		}
	}
	
	private func continueToCardSelection() {
		DispatchQueue.main.async {
			self.performSegue(withIdentifier: "Select Favourite Card", sender: self)
		}
	}
	
	/// Start animating `loadingIndicator`
	private func startLoading() {
		DispatchQueue.main.async {
			self.loadingIndicator.startAnimating()
			self.dismissButton.isEnabled = false
			self.dismissButton.isUserInteractionEnabled = false
		}
	}
	
	/// Stop animating `loadingIndicator`
	private func stopLoading() {
		DispatchQueue.main.async {
			self.loadingIndicator.stopAnimating()
			self.dismissButton.isEnabled = true
			self.dismissButton.isUserInteractionEnabled = true
		}
	}
    
	// MARK: IBActions
	/// User tapped the continue button
	@IBAction private func continueTapped(_ sender: UIButton) {
		self.proceed()
	}
	
	@IBAction private func signUpTapped(_ sender: UIButton) {
		self.signUp()
	}
	
	@IBAction private func skipTapped(_ sender: UIButton) {
		self.skip()
	}
	
	@IBAction private func dismissTapped(_ sender: UIButton) {
		self.dismiss(animated: true, completion: nil)
	}

}

extension AddOysterAccountViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == self.emailField {
			self.passwordField.becomeFirstResponder()
		} else {
			self.passwordField.resignFirstResponder()
		}
		
		return true
	}
	
}
