//
//  Text Field.swift
//  Interchange
//
//  Created by George Nick Gorzynski on 11/07/2018.
//  Copyright © 2018 g30r93g. All rights reserved.
//

import UIKit

// A bordered UITextField
@IBDesignable
class BorderedTextField: UITextField {
	
	@IBInspectable var cornerRadius: CGFloat = 0 {
		didSet {
			layer.cornerRadius = cornerRadius
		}
	}
	
	@IBInspectable var borderWidth: CGFloat = 0 {
		didSet {
			layer.borderWidth = borderWidth
		}
	}
	
	@IBInspectable var borderColor: UIColor = .clear {
		didSet {
			layer.borderColor = borderColor.cgColor
		}
	}
	
	@IBInspectable var placeholderColor: UIColor = .clear {
		didSet {
			self.attributedPlaceholder = NSAttributedString(string: self.placeholder != nil ? self.placeholder! : "", attributes: [NSAttributedString.Key.foregroundColor : placeholderColor])
		}
	}
	
	// Changes how far in the text shows
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 5)
    }
	
	// Changes how far in the edited text shows
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 5)
    }
	
}

// A bordered UITextField with a label on the left of the text field
@IBDesignable
class DetailTextField: BorderedTextField {
	
	@IBInspectable var leftText: String = "" {
		didSet {
			updateTextView()
		}
	}
	
	@IBInspectable var leftTextSize: CGFloat = 0 {
		didSet {
			updateTextView()
		}
	}
	
	@IBInspectable var leftTextColor: UIColor = .clear {
		didSet {
			updateTextView()
		}
	}
	
	@IBInspectable var leftTextContainer: UIColor = .clear {
		didSet {
			updateTextView()
		}
	}
	
	// Changes how far in the text shows
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 50, dy: 5)
    }
	
	// Changes how far in the edited text shows
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 50, dy: 5)
    }
	
	// Updates the appearance of the label
	private func updateTextView() {
		leftViewMode = .always
		
		let label = RoundLabel(frame: CGRect(x: 10, y: 0, width: 100, height: 20))
		label.cornerRadius = 5
		label.textAlignment = .center
		label.backgroundColor = leftTextContainer
		label.text = leftText
		label.textColor = leftTextColor
		label.font = UIFont(name: "Railway", size: leftTextSize)
		label.numberOfLines = 1
		label.clipsToBounds = true
		label.sizeToFit()
		label.frame = CGRect(x: 8, y: -1, width: 36, height: 20)
		
		let view = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 20))
		view.addSubview(label)
		leftView = view
	}
    
}
