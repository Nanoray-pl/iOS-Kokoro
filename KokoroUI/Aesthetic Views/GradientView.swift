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

	@Proxy(\.gradient.startPoint)
	public var startPoint: CGPoint

	@Proxy(\.gradient.endPoint)
	public var endPoint: CGPoint

	public var colors: [(location: Double, color: UIColor)]? {
		didSet {
			gradient.colors = colors?.map(\.color.cgColor)
			gradient.locations = colors?.map { $0.location as NSNumber }
		}
	}

	public init() {
		super.init(frame: .zero)
		isUserInteractionEnabled = false
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public func setColors(_ colors: [UIColor]) {
		self.colors = (0 ..< colors.count).map { (location: Double($0) / Double(colors.count - 1), color: colors[$0]) }
	}
}
#endif
