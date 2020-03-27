//
//  Round.swift
//  TfL Planner
//
//  Created by George Nick Gorzynski on 01/06/2019.
//  Copyright © 2019 g30r93g. All rights reserved.
//

import UIKit

// A round UIView
@IBDesignable
class RoundView: UIView {
	
	@IBInspectable var cornerRadius: CGFloat = 0.0 {
		didSet {
			layer.cornerRadius = cornerRadius
		}
	}
	
	@IBInspectable var borderColor: UIColor = .clear {
		didSet {
			layer.borderColor = borderColor.cgColor
		}
	}
	
	@IBInspectable var borderWidth: CGFloat = 0.0 {
		didSet {
			layer.borderWidth = borderWidth
		}
	}
	
}

// A rounded UIVisualEffectView
@IBDesignable
class RoundVisualEffectView: UIVisualEffectView {
	
	@IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
           self.updateCornerRadius()
        }
    }
	
	private func updateCornerRadius() {
		self.layer.cornerRadius = cornerRadius
	}
	
}

// A UIView that has the top left corner rounded
@IBDesignable
class RoundLeftView: UIView {
	
	@IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
           self.updateCornerRadius()
        }
    }
	
	private func updateCornerRadius() {
		self.layer.cornerRadius = cornerRadius
		self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
	}
	
}

// A round UIButton
@IBDesignable
class RoundButton: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
	
	@IBInspectable var imageAngle: CGFloat = 0.0 {
		didSet {
			self.imageView?.transform = CGAffineTransform(rotationAngle: (imageAngle * .pi/180))
		}
	}
    
}

// A round UIImageView
@IBDesignable
class RoundImageView: UIImageView {
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
	
	@IBInspectable var inset: CGFloat = 0.0 {
		didSet {
			self.image = self.image?.withAlignmentRectInsets(UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset))
		}
	}
    
}

// A round UILabel
@IBDesignable
class RoundLabel: UILabel {
	
	var padding: UIEdgeInsets {
		return UIEdgeInsets(top: yPadding, left: xPadding, bottom: yPadding, right: xPadding)
	}
    
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
	
	@IBInspectable var labelAngle: CGFloat = 0.0 {
		didSet {
			self.transform = CGAffineTransform(rotationAngle: (labelAngle * .pi/180))
		}
	}
	
	@IBInspectable var xPadding: CGFloat = 4.0 {
		didSet {
			applyPadding()
		}
	}
	
	@IBInspectable var yPadding: CGFloat = 4.0 {
		didSet {
			applyPadding()
		}
	}
	
	func applyPadding() {
		self.frame.inset(by: self.padding)
	}
	
}

// A round UITableView
@IBDesignable
class RoundTableView: UITableView {
	
	@IBInspectable var cornerRadius: CGFloat = 0.0 {
		didSet {
			layer.cornerRadius = cornerRadius
		}
	}
	
	@IBInspectable var borderColor: UIColor = .clear {
		didSet {
			layer.borderColor = borderColor.cgColor
		}
	}
	
	@IBInspectable var borderWidth: CGFloat = 0.0 {
		didSet {
			layer.borderWidth = borderWidth
		}
	}
	
}

// A round UICollectionViewCell
@IBDesignable
class RoundUICollectionViewCell: UICollectionViewCell {
	
	@IBInspectable var cornerRadius: CGFloat = 0.0 {
		didSet {
			layer.cornerRadius = cornerRadius
		}
	}
	
}
