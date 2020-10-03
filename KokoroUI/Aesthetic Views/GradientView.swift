//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class GradientView: UIView {
	public override class var layerClass: AnyClass {
		return CAGradientLayer.classForCoder()
	}

	private lazy var gradient = layer as! CAGradientLayer

	public var startPoint: CGPoint {
		get {
			return gradient.startPoint
		}
		set {
			gradient.startPoint = newValue
		}
	}

	public var endPoint: CGPoint {
		get {
			return gradient.endPoint
		}
		set {
			gradient.endPoint = newValue
		}
	}

	public var colors: [(location: Double, color: UIColor)]? {
		didSet {
			gradient.colors = colors?.map { $0.color.cgColor }
			gradient.locations = colors?.map { $0.location as NSNumber }
		}
	}

	public func setColors(_ colors: [UIColor]) {
		self.colors = (0 ..< colors.count).map { (location: Double($0) / Double(colors.count - 1), color: colors[$0]) }
	}
}
#endif
