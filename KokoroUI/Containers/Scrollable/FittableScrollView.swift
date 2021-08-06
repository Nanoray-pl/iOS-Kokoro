//
//  Created on 06/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class FittableScrollView: UIScrollView {
	public let scrollableContentBehavior: ScrollableContentBehavior

	private var contentSizeObservation: NSKeyValueObservation?

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
}
#endif
