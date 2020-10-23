//
//  Created on 23/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class HeaderFooterCollectionView: UICollectionView {
	private var contentSizeObservation: NSKeyValueObservation?

	/// Whether scrolling should be disabled and scroll offset be locked at the top of the content.
	public var isScrollLocked = false {
		didSet {
			isScrollEnabled = !isScrollLocked
		}
	}

	public var topInset: CGFloat = 0 {
		didSet {
			contentInset.top = topInset + (headerViewWrapper?.frame.height ?? 0)
		}
	}

	public var bottomInset: CGFloat = 0 {
		didSet {
			contentInset.bottom = bottomInset + (footerViewWrapper?.frame.height ?? 0)
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

	private var footerViewWrapperVerticalConstraint: NSLayoutConstraint?

	private lazy var privateDelegate = Delegate(parent: self) // swiftlint:disable:this weak_delegate

	public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
		super.init(frame: frame, collectionViewLayout: layout)
		contentSizeObservation = observe(\.contentSize) { [weak self] _, _ in self?.updateFooterConstraint() }
	}

	public required init?(coder: NSCoder) {
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

	private func updateTopInset() {
		contentInset.top = topInset + (headerViewWrapper?.frame.height ?? 0)
		if isScrollLocked {
			contentOffset.y = -contentInset.top
		}
	}

	private func updateBottomInset() {
		contentInset.bottom = bottomInset + (footerViewWrapper?.frame.height ?? 0)
	}

	private func updateFooterConstraint() {
		footerViewWrapperVerticalConstraint?.constant = contentSize.height
	}

	private class Delegate: FrameObservingViewDelegate {
		private unowned let parent: HeaderFooterCollectionView

		init(parent: HeaderFooterCollectionView) {
			self.parent = parent
		}

		func didChangeFrame(from oldFrame: CGRect, to newFrame: CGRect, in view: FrameObservingView) {
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
