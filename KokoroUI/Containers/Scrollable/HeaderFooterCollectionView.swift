//
//  Created on 23/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class HeaderFooterCollectionView: UICollectionView {
	private var contentSizeObservation: NSKeyValueObservation?

	public var realContentOffset: CGPoint {
		return .init(x: contentOffset.x, y: contentOffset.y + contentInset.top + (headerViewWrapper?.frame.height ?? 0))
	}

	public var topInset: CGFloat = 0 {
		didSet {
			updateTopInset()
		}
	}

	public var bottomInset: CGFloat = 0 {
		didSet {
			updateBottomInset()
		}
	}

	public var headerView: UIView? {
		didSet {
			headerViewWrapper = headerView.flatMap {
				return FrameObservingView(wrapping: $0).with {
					$0.isUserInteractionEnabled = true
					$0.delegate = privateDelegate
				}
			}
		}
	}

	public var footerView: UIView? {
		didSet {
			footerViewWrapper = footerView.flatMap {
				return FrameObservingView(wrapping: $0).with {
					$0.isUserInteractionEnabled = true
					$0.delegate = privateDelegate
				}
			}
		}
	}

	private var headerViewWrapper: FrameObservingView? {
		didSet {
			oldValue?.removeFromSuperview()
			if let wrapper = headerViewWrapper {
				addSubview(wrapper)
				wrapper.bottomToTop(of: contentLayoutGuide).priority(.init(999)).activate()
				wrapper.horizontalEdgesToSuperview().activate()
				wrapper.width(to: self).priority(.init(999)).activate()
				wrapper.layoutIfNeeded()
			}
			updateTopInset()
		}
	}

	private var footerViewWrapper: FrameObservingView? {
		didSet {
			footerViewWrapperVerticalConstraint = nil
			oldValue?.removeFromSuperview()
			if let wrapper = footerViewWrapper {
				addSubview(wrapper)
				footerViewWrapperVerticalConstraint = wrapper.topToBottom(of: contentLayoutGuide).priority(.init(999))
				footerViewWrapperVerticalConstraint?.activate()
				wrapper.horizontalEdgesToSuperview().activate()
				wrapper.width(to: self).priority(.init(999)).activate()
				wrapper.layoutIfNeeded()
			}
			updateBottomInset()
		}
	}

	private lazy var privateDelegate = PrivateDelegate(parent: self) // swiftlint:disable:this weak_delegate
	private var footerViewWrapperVerticalConstraint: NSLayoutConstraint?
	private var lastContentSize = CGSize.zero

	public let scrollableContentBehavior: ScrollableContentBehavior

	public override var intrinsicContentSize: CGSize {
		switch scrollableContentBehavior {
		case .fitContent:
			var height = collectionViewLayout.collectionViewContentSize.height + (headerViewWrapper?.frame.height ?? 0) + (footerViewWrapper?.frame.height ?? 0)
			if height == 0 && (0 ..< numberOfSections).map({ numberOfItems(inSection: $0) }).reduce(0, +) > 0 {
				// forcing a non-0 height to let the layout actually calculate its attributes - otherwise `contentSize.height` will always be 0
				height = UIScreen.main.bounds.height
			}
			return .init(
				width: collectionViewLayout.collectionViewContentSize.width,
				height: height
			)
		case .scrollable:
			return super.intrinsicContentSize
		}
	}

	public init(frame: CGRect = .init(origin: .zero, size: UIScreen.main.bounds.size), scrollableContentBehavior: ScrollableContentBehavior = .scrollable, collectionViewLayout layout: UICollectionViewLayout) {
		self.scrollableContentBehavior = scrollableContentBehavior
		super.init(frame: frame, collectionViewLayout: layout)
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

	public override func didMoveToWindow() {
		super.didMoveToWindow()
		if window == nil { return }

		updateTopInset()
		updateBottomInset()
		updateFooterConstraint()
		collectionViewLayout.invalidateLayout()
	}

	public func setRealContentOffset(_ offset: CGPoint, animated: Animated) {
		setContentOffset(.init(x: offset.x, y: offset.y - contentInset.top - (headerViewWrapper?.frame.height ?? 0)), animated: animated.value)
	}

	private func didChangeContentSize() {
		let intrinsicContentSize = self.intrinsicContentSize
		if bounds.size != intrinsicContentSize && intrinsicContentSize.width >= 0 && intrinsicContentSize.height >= 0 {
			updateFooterConstraint()
			invalidateIntrinsicContentSize()
		}
	}

	private func updateTopInset() {
		contentInset.top = topInset + (headerViewWrapper?.frame.height ?? 0)
		switch scrollableContentBehavior {
		case .scrollable:
			break
		case .fitContent:
			contentOffset.y = -contentInset.top
		}
	}

	private func updateBottomInset() {
		contentInset.bottom = bottomInset + (footerViewWrapper?.frame.height ?? 0)
	}

	private func updateFooterConstraint() {
		footerViewWrapperVerticalConstraint?.constant = contentSize.height
	}

	private class PrivateDelegate: FrameObservingViewDelegate {
		private weak var parent: HeaderFooterCollectionView?

		init(parent: HeaderFooterCollectionView) {
			self.parent = parent
		}

		func didChangeFrame(from oldFrame: CGRect, to newFrame: CGRect, in view: FrameObservingView) {
			guard let parent = parent else { return }
			switch view {
			case parent.headerViewWrapper:
				parent.contentOffset.y -= (newFrame.height - oldFrame.height)
				parent.updateTopInset()
				parent.updateFooterConstraint()
			case parent.footerViewWrapper:
				parent.updateBottomInset()
				parent.updateFooterConstraint()
			default:
				break
			}
		}
	}
}
#endif
