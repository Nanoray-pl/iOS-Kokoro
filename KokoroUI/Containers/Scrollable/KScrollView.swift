//
//  Created on 06/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class KScrollView: UIScrollView {
	public let scrollableContentBehavior: ScrollableContentBehavior

	/// Setting this property to `true` makes the view ignore and pass on all of the touches it receives, unless it's currently being scrolled. Defaults to `false`.
	public var ignoresTaps = false

	private var contentSizeObservation: NSKeyValueObservation?
	private var ignoredTouches = Set<UITouch>()

	public override var intrinsicContentSize: CGSize {
		switch scrollableContentBehavior {
		case .fitContent:
			return contentSize
		case .scrollable:
			return super.intrinsicContentSize
		}
	}

	public init(frame: CGRect = .init(origin: .zero, size: UIScreen.main.bounds.size), scrollableContentBehavior: ScrollableContentBehavior = .scrollable) {
		self.scrollableContentBehavior = scrollableContentBehavior
		super.init(frame: frame)
		contentSizeObservation = observe(\.contentSize) { [weak self] _, _ in self?.didChangeContentSize() }

		switch scrollableContentBehavior {
		case .scrollable:
			isScrollEnabled = true
		case .fitContent:
			isScrollEnabled = false
			contentInsetAdjustmentBehavior = .never
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func didChangeContentSize() {
		let intrinsicContentSize = self.intrinsicContentSize
		if bounds.size != intrinsicContentSize && intrinsicContentSize.width >= 0 && intrinsicContentSize.height >= 0 {
			invalidateIntrinsicContentSize()
		}
	}

	public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if isDragging || !ignoresTaps {
			super.touchesBegan(touches, with: event)
			return
		}

		touches.forEach { ignoredTouches.insert($0) }
		next?.touchesBegan(touches, with: event)
	}

	public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		let currentActiveTouches = touches.subtracting(ignoredTouches)
		let currentIgnoredTouches = touches.subtracting(currentActiveTouches)

		if !currentActiveTouches.isEmpty {
			super.touchesMoved(currentActiveTouches, with: event)
		}
		if !currentIgnoredTouches.isEmpty {
			next?.touchesMoved(currentIgnoredTouches, with: event)
		}
	}

	public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		let currentActiveTouches = touches.subtracting(ignoredTouches)
		let currentIgnoredTouches = touches.subtracting(currentActiveTouches)
		touches.forEach { ignoredTouches.remove($0) }

		if !currentActiveTouches.isEmpty {
			super.touchesEnded(currentActiveTouches, with: event)
		}
		if !currentIgnoredTouches.isEmpty {
			next?.touchesEnded(currentIgnoredTouches, with: event)
		}
	}

	public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		let currentActiveTouches = touches.subtracting(ignoredTouches)
		let currentIgnoredTouches = touches.subtracting(currentActiveTouches)
		touches.forEach { ignoredTouches.remove($0) }

		if !currentActiveTouches.isEmpty {
			super.touchesCancelled(currentActiveTouches, with: event)
		}
		if !currentIgnoredTouches.isEmpty {
			next?.touchesCancelled(currentIgnoredTouches, with: event)
		}
	}
}
#endif
