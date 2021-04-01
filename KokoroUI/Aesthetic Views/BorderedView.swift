//
//  Created on 23/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class BorderedView: UIView {
	public var borderInsets: EdgeInsets = UIEdgeInsets(top: 1.0 / UIScreen.main.scale, left: 0, bottom: 1.0 / UIScreen.main.scale, right: 0) {
		didSet {
			updateBorderFrames()
			updateContentConstraints()
		}
	}

	public var borderColor = UIColor.label.withAlphaComponent(0.5) {
		didSet {
			updateBorderColor()
		}
	}

	public private(set) var contentView: UIView!

	private var contentViewConstraints: Constraints? {
		didSet {
			oldValue?.deactivate()
			contentViewConstraints?.activate()
		}
	}

	private lazy var topBorder = createBorderLayer()
	private lazy var bottomBorder = createBorderLayer()
	private lazy var leftBorder = createBorderLayer()
	private lazy var rightBorder = createBorderLayer()
	private lazy var borderLayers = [topBorder, bottomBorder, leftBorder, rightBorder]

	public override init(frame: CGRect) {
		super.init(frame: frame)
		buildUI()
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func buildUI() {
		contentView = UIView().with { [parent = self] in
			parent.addSubview($0)
		}

		updateBorderFrames()
		updateContentConstraints()
		updateBorderColor()
	}

	private func createBorderLayer() -> CALayer {
		let layer = CALayer()
		self.layer.addSublayer(layer)
		return layer
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		updateBorderFrames()
	}

	private func updateBorderFrames() {
		topBorder.frame = CGRect(x: 0, y: 0, width: frame.width, height: borderInsets.top)
		bottomBorder.frame = CGRect(x: 0, y: frame.height - borderInsets.bottom, width: frame.width, height: borderInsets.bottom)
		leftBorder.frame = CGRect(x: 0, y: borderInsets.top, width: borderInsets.left(isRightToLeft: isRightToLeft), height: frame.height - borderInsets.top - borderInsets.bottom)
		rightBorder.frame = CGRect(x: frame.width - borderInsets.right(isRightToLeft: isRightToLeft), y: borderInsets.top, width: borderInsets.right(isRightToLeft: isRightToLeft), height: frame.height - borderInsets.top - borderInsets.bottom)
	}

	private func updateBorderColor() {
		let cgColor = borderColor.cgColor
		borderLayers.forEach { $0.backgroundColor = cgColor }
	}

	private func updateContentConstraints() {
		contentViewConstraints = contentView.edgesToSuperview(insets: borderInsets)
	}
}
#endif
