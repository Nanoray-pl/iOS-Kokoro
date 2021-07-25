//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public protocol FrameObservingViewDelegate: AnyObject {
	func didChangeFrame(from oldFrame: CGRect, to newFrame: CGRect, in view: FrameObservingView)
}

public class FrameObservingView: UIView {
	public weak var delegate: FrameObservingViewDelegate?

	private var lastFrame: CGRect = .zero

	public convenience init(wrapping view: UIView) {
		self.init()
		addSubview(view)
		view.edges(to: self).activate()
	}

	public init() {
		super.init(frame: .zero)
		isUserInteractionEnabled = false
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		guard lastFrame != frame else { return }

		delegate?.didChangeFrame(from: lastFrame, to: frame, in: self)
		lastFrame = frame
	}
}
#endif
