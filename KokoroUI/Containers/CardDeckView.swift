//
//  Created on 15/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public class CardDeckView<ContentView: UIView>: LazyInitView {
	public enum Orientation {
		/// First subview on the left of the view, last subview near the right of the view.
		case leftToRight

		/// First subview on the right of the view, last subview near the left of the view.
		case rightToLeft

		/// First subview on the top of the view, last subview near the bottom of the view.
		case topToBottom

		/// First subview on the bottom of the view, last subview near the top of the view.
		case bottomToTop
	}

	/// Defines how should a split card group behave when there is a lot of space.
	public enum SplitCardGroupPosition {
		/// The split card group will be right next to the other group.
		case near

		/// The split card group will be on the edge of the view.
		case far
	}

	private class EntryView: UIView, UIViewSubviewObserver {
		private weak var parent: CardDeckView<ContentView>?
		private(set) weak var contentView: ContentView?
		private let observation: NSKeyValueObservation

		var entryConstraints = [NSLayoutConstraint]() {
			didSet {
				oldValue.deactivate()
				entryConstraints.activate()
			}
		}

		init(with contentView: ContentView, parent: CardDeckView<ContentView>) {
			self.contentView = contentView
			self.parent = parent
			observation = contentView.observe(\.isHidden) { [weak parent] _, _ in parent?.updateLayout() }
			super.init(frame: .zero)
			addSubview(contentView)
			contentView.edgesToSuperview().activate()
			addSubviewObserver(self)
		}

		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		func didAddSubview(_ subview: UIView, to view: UIView) {
			// do nothing
		}

		func didRemoveSubview(_ subview: UIView, from view: UIView) {
			removeFromSuperview()
			parent?.entryViews.removeFirst { $0 === self }
			parent?.isDirty = true
			DispatchQueue.main.async { [weak parent] in parent?.updateLayoutIfNeeded() }
		}
	}

	public var contentInsets = UIEdgeInsets.zero {
		didSet {
			if oldValue == contentInsets { return }
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	public var orientation = Orientation.leftToRight {
		didSet {
			if oldValue == orientation { return }
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	public var itemSize = CGSize(width: 100, height: 140) {
		didSet {
			if oldValue == itemSize { return }
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	public var maxGroupedSpacing: CGFloat? = 20 {
		didSet {
			if oldValue == maxGroupedSpacing { return }
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	public var splitSpacing: CGFloat = 20 {
		didSet {
			if oldValue == splitSpacing { return }
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	public var splitCardGroupPosition = SplitCardGroupPosition.near {
		didSet {
			if oldValue == splitCardGroupPosition { return }
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	public var scrollingLocksOntoItems = true

	private var scrollView: UIScrollView!
	private var contentView: UIView!

	private lazy var privateDelegate = PrivateDelegate(parent: self) // swiftlint:disable:this weak_delegate
	private var isDirty = true
	private var entryViews = [EntryView]()
	private var scrollIndex = 0
	private var lastItemScrollLength: CGFloat = 0

	private var lengthConstraint: NSLayoutConstraint? {
		didSet {
			oldValue?.deactivate()
			lengthConstraint?.activate()
		}
	}

	private var contentOffsetConstraint: NSLayoutConstraint? {
		didSet {
			oldValue?.deactivate()
			contentOffsetConstraint?.activate()
		}
	}

	public init() {
		super.init(frame: .zero)
		buildUI()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func buildUI() {
		var constraints = ConstraintSet()
		defer { constraints.activate() }

		FrameObservingView().with { [parent = self] in
			$0.delegate = privateDelegate
			parent.addSubview($0)
			constraints += $0.edgesToSuperview()
		}

		scrollView = UIScrollView().with { [parent = self] in
			$0.delegate = privateDelegate
			$0.showsVerticalScrollIndicator = false
			$0.showsHorizontalScrollIndicator = false
			$0.decelerationRate = .fast

			contentView = UIView().with { [parent = $0] in
				parent.addSubview($0)
				constraints += $0.size(to: parent)
			}

			parent.addSubview($0)
			constraints += $0.edgesToSuperview()
		}

		updateLayout()
	}

	public override func initializeView() {
		super.initializeView()
		updateLayoutIfNeeded()
	}

	public func scrollToItem(at index: Int, animated: Bool) {
		scrollIndex = index
		scrollView.setContentOffset(.init(
			x: orientational(vertical: 0, horizontal: CGFloat(index) * itemSize.width),
			y: orientational(vertical: CGFloat(index) * itemSize.height, horizontal: 0)
		), animated: animated)
	}

	public func addArrangedSubview(_ view: ContentView) {
		insertArrangedSubview(view, at: entryViews.count)
	}

	public func insertArrangedSubview(_ view: ContentView, at index: Int) {
		let entryView = EntryView(with: view, parent: self)
		contentView.addSubview(entryView)
		entryViews.insert(entryView, at: index)
		if isInitialized {
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	public func removeArrangedSubview(_ view: ContentView) {
		guard let index = entryViews.firstIndex(where: { $0.contentView == view }) else { return }
		let entryView = entryViews[index]
		entryViews.remove(at: index)
		entryView.removeFromSuperview()
		if isInitialized {
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	private func cleanUpEntryViews(andUpdateLayout updateLayout: Bool = true) {
		let oldCount = entryViews.count
		entryViews = entryViews.filter { $0.contentView != nil }
		contentView.subviews.filter(ofType: EntryView.self).filter { $0.contentView == nil }.forEach { $0.removeFromSuperview() }
		if updateLayout && entryViews.count != oldCount && isInitialized {
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	private func updateLayoutIfNeeded() {
		guard isDirty else { return }
		updateLayout()
	}

	private func updateLayout() {
		isDirty = false

		cleanUpEntryViews(andUpdateLayout: false)
		lengthConstraint = orientational(
			vertical: width(of: itemSize.width + contentInsets.horizontal),
			horizontal: height(of: itemSize.height + contentInsets.vertical)
		)
		updateLayoutConstraints()
	}

	private func updateLayoutConstraints() {
		let visibleEntryViews = entryViews.filter { $0.contentView?.isHidden == false }
		if visibleEntryViews.isEmpty { return }
		let itemLength = orientational(itemSize, vertical: \.height, horizontal: \.width)
		let collectionViewLength = orientational(frame, vertical: \.height, horizontal: \.width)
		let workingLength = collectionViewLength - orientational(contentInsets, vertical: \.vertical, horizontal: \.horizontal)
		let minL = orientational(contentInsets, vertical: \.top, horizontal: \.left)
		let maxL = orientational(
			vertical: frame.height - contentInsets.bottom,
			horizontal: frame.width - contentInsets.right
		)

		let directionMultiplier: CGFloat
		let firstGroupStart: CGFloat
		var firstGroupEnd: CGFloat
		var secondGroupStart: CGFloat
		var secondGroupEnd: CGFloat

		var firstGroupLength: CGFloat {
			return firstGroupEnd - firstGroupStart
		}
		var secondGroupLength: CGFloat {
			return secondGroupEnd - secondGroupStart
		}

		switch orientation {
		case .leftToRight, .topToBottom:
			directionMultiplier = 1
			firstGroupStart = minL
		case .rightToLeft, .bottomToTop:
			directionMultiplier = -1
			firstGroupStart = maxL
		}
		firstGroupEnd = firstGroupStart + (workingLength - itemLength - splitSpacing) * directionMultiplier
		let baseSpacing = (firstGroupLength - itemLength) / CGFloat(visibleEntryViews.count - 2)
		firstGroupEnd += baseSpacing

		secondGroupEnd = firstGroupStart + workingLength * directionMultiplier
		secondGroupStart = secondGroupEnd - firstGroupLength

		if let maxGroupedSpacing = maxGroupedSpacing {
			let currentSpacing = (abs(firstGroupLength) - itemLength) / CGFloat(visibleEntryViews.count - 1)
			if maxGroupedSpacing < currentSpacing {
				let newGroupLength = maxGroupedSpacing * CGFloat(visibleEntryViews.count - 1) + itemLength
				firstGroupEnd = firstGroupStart + newGroupLength * directionMultiplier
				secondGroupStart = secondGroupEnd - newGroupLength * directionMultiplier
			}
		}

		switch splitCardGroupPosition {
		case .near:
			let currentSpacing = (abs(firstGroupLength) - itemLength) / CGFloat(visibleEntryViews.count - 1)
			secondGroupEnd = firstGroupEnd + (splitSpacing + itemLength - currentSpacing) * directionMultiplier
			secondGroupStart = secondGroupEnd - firstGroupLength
		case .far:
			break
		}

		let baseScrollPosition = orientational(scrollView.contentOffset, vertical: \.y, horizontal: \.x)
		let mirroredIfNeededScrollPosition: CGFloat
		switch orientation {
		case .leftToRight, .topToBottom:
			mirroredIfNeededScrollPosition = -baseScrollPosition
		case .rightToLeft, .bottomToTop:
			mirroredIfNeededScrollPosition = baseScrollPosition
		}

		let itemScrollLength = abs(secondGroupStart - firstGroupStart)
		lastItemScrollLength = itemScrollLength
		let mappedScrollPosition = mirroredIfNeededScrollPosition / itemScrollLength
		let firstPositionMultiplier = mappedScrollPosition < 0 ? 1 / (abs(mappedScrollPosition) + 1) : 1
		let secondPositionMultiplier = mappedScrollPosition > CGFloat(visibleEntryViews.count) ? 1 / (abs(mappedScrollPosition - CGFloat(visibleEntryViews.count)) + 1) : 1

		let newFirstGroupLength = ((abs(firstGroupLength) - itemLength) * firstPositionMultiplier + itemLength) * directionMultiplier
		firstGroupEnd = firstGroupStart + newFirstGroupLength
		let newSecondGroupLength = ((abs(secondGroupLength) - itemLength) * secondPositionMultiplier + itemLength) * directionMultiplier
		secondGroupStart = secondGroupEnd - newSecondGroupLength

		visibleEntryViews.enumerated().forEach { index, entryView in
			var constraints: [NSLayoutConstraint] = orientational(
				vertical: [
					entryView.leftToSuperview(inset: contentInsets.left),
					entryView.rightToSuperview(inset: contentInsets.right),
				],
				horizontal: [
					entryView.topToSuperview(inset: contentInsets.top),
					entryView.bottomToSuperview(inset: contentInsets.bottom),
				]
			)
			constraints.append(contentsOf: entryView.size(of: itemSize))

			let position: CGFloat
			if visibleEntryViews.count == 1 {
				switch orientation {
				case .leftToRight, .topToBottom:
					position = firstGroupStart
				case .rightToLeft, .bottomToTop:
					position = firstGroupStart - itemLength
				}
			} else {
				let itemIndexFraction = visibleEntryViews.count == 1 ? 0 : CGFloat(index) / CGFloat(visibleEntryViews.count - 1)
				var firstPosition = firstGroupStart + (abs(firstGroupLength) - itemLength) * itemIndexFraction * directionMultiplier
				var secondPosition = secondGroupStart + (abs(secondGroupLength) - itemLength) * itemIndexFraction * directionMultiplier
				switch orientation {
				case .rightToLeft, .bottomToTop:
					firstPosition -= itemLength
					secondPosition -= itemLength
				case .leftToRight, .topToBottom:
					break
				}

				let fraction = (mappedScrollPosition - CGFloat(visibleEntryViews.count - 1) + CGFloat(index)).clamped(to: 0 ... 1)
				position = firstPosition + (secondPosition - firstPosition) * fraction
			}

			switch orientation {
			case .leftToRight, .rightToLeft:
				constraints += entryView.leftToSuperview(inset: position.isNaN ? 0 : position)
			case .topToBottom, .bottomToTop:
				constraints += entryView.topToSuperview(inset: position.isNaN ? 0 : position)
			}

			entryView.entryConstraints = constraints
		}

		let scrollableContentLength = CGFloat(visibleEntryViews.count) * itemScrollLength
		scrollView.contentSize = .init(
			width: orientational(vertical: frame.width, horizontal: frame.width + scrollableContentLength),
			height: orientational(vertical: frame.height + scrollableContentLength, horizontal: frame.height)
		)
		switch orientation {
		case .leftToRight:
			scrollView.contentInset = .init(top: 0, left: scrollableContentLength, bottom: 0, right: -scrollableContentLength)
		case .topToBottom:
			scrollView.contentInset = .init(top: scrollableContentLength, left: 0, bottom: -scrollableContentLength, right: 0)
		case .rightToLeft, .bottomToTop:
			scrollView.contentInset = .zero
		}

		contentOffsetConstraint = orientational(
			vertical: contentView.topToSuperview(inset: scrollView.contentOffset.y),
			horizontal: contentView.leftToSuperview(inset: scrollView.contentOffset.x)
		)
	}

	private func orientational<Value>(vertical: @autoclosure () -> Value, horizontal: @autoclosure () -> Value) -> Value {
		switch orientation {
		case .topToBottom, .bottomToTop:
			return vertical()
		case .leftToRight, .rightToLeft:
			return horizontal()
		}
	}

	private func orientational<Root, Value>(_ root: Root, vertical: (Root) -> Value, horizontal: (Root) -> Value) -> Value {
		switch orientation {
		case .topToBottom, .bottomToTop:
			return vertical(root)
		case .leftToRight, .rightToLeft:
			return horizontal(root)
		}
	}

	private class PrivateDelegate: NSObject, FrameObservingViewDelegate, UIScrollViewDelegate {
		private weak var parent: CardDeckView<ContentView>?

		init(parent: CardDeckView<ContentView>) {
			self.parent = parent
		}

		func didChangeFrame(from oldFrame: CGRect, to newFrame: CGRect, in view: FrameObservingView) {
			guard let parent = parent else { return }
			parent.scrollToItem(at: parent.scrollIndex, animated: false)
			parent.updateLayoutConstraints()
		}

		func scrollViewDidScroll(_ scrollView: UIScrollView) {
			parent?.updateLayoutConstraints()
		}

		func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
			guard let parent = parent, parent.scrollingLocksOntoItems else { return }
			let contentLength = parent.orientational(scrollView.contentSize, vertical: \.height, horizontal: \.width)
			var targetPosition = parent.orientational(targetContentOffset.pointee, vertical: \.y, horizontal: \.x)
			switch parent.orientation {
			case .leftToRight, .topToBottom:
				if targetPosition >= 0 { return }
				if targetPosition <= -contentLength { return }
			case .rightToLeft, .bottomToTop:
				if targetPosition <= 0 { return }
				if targetPosition >= contentLength { return }
			}

			targetPosition = round(targetPosition / parent.lastItemScrollLength) * parent.lastItemScrollLength
			switch parent.orientation {
			case .leftToRight, .rightToLeft:
				targetContentOffset.pointee.x = targetPosition
			case .topToBottom, .bottomToTop:
				targetContentOffset.pointee.y = targetPosition
			}
		}
	}
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct CardDeckViewPreviews: PreviewProvider {
	static var previews: some View {
		representable(width: .device, height: .compressed) {
			CardDeckView<UIView>().with {
//				$0.contentInsets = .init(insets: 4)
				$0.splitSpacing = 10
				$0.splitCardGroupPosition = .near
				$0.orientation = .leftToRight

				for index in 0 ..< 13 {
					RoundedView().with { [parent = $0] in
						$0.rounding = .rectangle(radius: .points(16))

						UIView().with { [parent = $0] in
							let colors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemTeal, .systemBlue, .systemPurple]
							$0.backgroundColor = colors[index % colors.count]

							parent.addSubview($0)
							$0.edgesToSuperview().activate()
						}

						parent.addArrangedSubview($0)
					}
				}
				$0.scrollToItem(at: 3, animated: false)
			}
		}
	}
}
#endif
#endif
