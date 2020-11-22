//
//  Created on 22/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

/// A view with an embedded `UIImageView`, which tries to keep its aspect ratio equal to the aspect ratio of the image it's displaying.
public class RatioImageView: UIView {
	public var image: UIImage? {
		didSet {
			if let image = image, isAutomaticallyChangingRatio {
				setRatio(image.size)
			}
		}
	}

	public var ratioConstraintPriority: UILayoutPriority {
		didSet {
			if let ratioConstraint = ratioConstraint {
				setRatio(CGSize(width: ratioConstraint.multiplier, height: 1))
			}
		}
	}

	public var isAutomaticallyChangingRatio = true

	private var imageView: UIImageView!

	private var ratioConstraint: NSLayoutConstraint? {
		didSet {
			oldValue?.deactivate()
			ratioConstraint?.activate()
		}
	}

	public init(ratioConstraintPriority: UILayoutPriority = .required) {
		self.ratioConstraintPriority = ratioConstraintPriority
		super.init(frame: .zero)
		buildUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func buildUI() {
		var constraints = ConstraintSet()
		defer { constraints.activate() }

		imageView = UIImageView(frame: .zero).with { [parent = self] in
			$0.contentMode = .scaleAspectFill
			$0.clipsToBounds = true
			parent.addSubview($0)
			constraints += $0.edgesToSuperview()
		}
	}

	public func setRatio(_ ratio: CGSize) {
		ratioConstraint = imageView.ratio(size: ratio).priority(ratioConstraintPriority)
	}
}
#endif
