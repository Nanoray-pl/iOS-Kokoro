//
//  Created on 15/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public protocol CardDeckViewObserver: AnyObject {
	associatedtype ContentView: UIView

	func didScroll(to position: CGFloat, in view: CardDeckView<ContentView>)
	func didEndDragging(targetPosition: CGFloat, in view: CardDeckView<ContentView>)
}

public extension CardDeckViewObserver {
	func didScroll(to position: CGFloat, in view: CardDeckView<ContentView>) {}
	func didEndDragging(targetPosition: CGFloat, in view: CardDeckView<ContentView>) {}
}

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

	/// Defines how should the items be ordered in the deck.
	public enum ItemOrder {
		/// The first item will be on top of the deck (the last item will be at the bottom).
		case topFirst

		/// The last item will be on top of the deck (the first item will be at the bottom).
		case topLast
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

	private class WeakObserver: CardDeckViewObserver {
		let identifier: ObjectIdentifier
		private(set) weak var weakReference: AnyObject?
		private let didScrollClosure: (CGFloat, CardDeckView<ContentView>) -> Void
		private let didEndDraggingClosure: (CGFloat, CardDeckView<ContentView>) -> Void

		init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: CardDeckViewObserver, Wrapped.ContentView == ContentView {
			identifier = ObjectIdentifier(wrapped)
			weakReference = wrapped
			didScrollClosure = { [weak wrapped] in wrapped?.didScroll(to: $0, in: $1) }
			didEndDraggingClosure = { [weak wrapped] in wrapped?.didEndDragging(targetPosition: $0, in: $1) }
		}

		func didScroll(to position: CGFloat, in view: CardDeckView<ContentView>) {
			didScrollClosure(position, view)
		}

		func didEndDragging(targetPosition: CGFloat, in view: CardDeckView<ContentView>) {
			didEndDraggingClosure(targetPosition, view)
		}
	}

	private struct CalculatedStaticLayout {
		let itemSize: CGSize
		let itemLength: CGFloat
		let collectionViewLength: CGFloat
		let workingLength: CGFloat
		let firstGroupStart: CGFloat
		let firstGroupEnd: CGFloat
		let secondGroupStart: CGFloat
		let secondGroupEnd: CGFloat

		var firstGroupLength: CGFloat {
			return firstGroupEnd - firstGroupStart
		}

		var secondGroupLength: CGFloat {
			return secondGroupEnd - secondGroupStart
		}
	}

	private struct CalculatedScrollLayout {
		let staticLayout: CalculatedStaticLayout
		let itemScrollLength: CGFloat
		let mappedScrollPosition: CGFloat
		let firstGroupEnd: CGFloat
		let secondGroupStart: CGFloat

		var firstGroupStart: CGFloat {
			return staticLayout.firstGroupStart
		}

		var secondGroupEnd: CGFloat {
			return staticLayout.secondGroupEnd
		}

		var firstGroupLength: CGFloat {
			return firstGroupEnd - firstGroupStart
		}

		var secondGroupLength: CGFloat {
			return secondGroupEnd - secondGroupStart
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

	public var itemOrder = ItemOrder.topFirst {
		didSet {
			if oldValue == itemOrder { return }
			isDirty = true
			DispatchQueue.main.async { self.updateLayoutIfNeeded() }
		}
	}

	public var itemRatio: CGFloat = 5.0 / 7.0 {
		didSet {
			if oldValue == itemRatio { return }
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

	@Proxy(\.scrollView.ignoresTaps)
	public var ignoresTaps: Bool

	private var itemSize: CGSize {
		return orientational(
			vertical: .init(width: frame.width - contentInsets.horizontal, height: (frame.width - contentInsets.horizontal) / itemRatio),
			horizontal: .init(width: (frame.height - contentInsets.vertical) * itemRatio, height: frame.height - contentInsets.vertical)
		)
	}

	public var scrollingLocksOntoItems = true

	private var scrollView: KScrollView!
	private var contentView: UIView!

	private lazy var privateDelegate = PrivateDelegate(parent: self) // swiftlint:disable:this weak_delegate
	private var isDirty = true
	private var entryViews = [EntryView]()
	private var scrollPositionIsAtEnd = false
	private var calculatedStaticLayout: CalculatedStaticLayout?
	private var calculatedScrollLayout: CalculatedScrollLayout?

	private(set) var scrollPosition: CGFloat = 0 {
		didSet {
			scrollPositionIsAtEnd = abs(scrollPosition - CGFloat(visibleEntryViews.count)) < 0.005
		}
	}

	private var contentOffsetConstraint: NSLayoutConstraint? {
		didSet {
			oldValue?.deactivate()
			contentOffsetConstraint?.activate()
		}
	}

	private var visibleEntryViews: [EntryView] {
		let visibleEntryViews = entryViews.filter { $0.contentView?.isHidden == false }
		switch itemOrder {
		case .topFirst:
			return visibleEntryViews.reversed()
		case .topLast:
			return visibleEntryViews
		}
	}

	private let observers = BoxedObserverSet<WeakObserver, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

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

		scrollView = KScrollView().with { [parent = self] in
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

	public func addObserver<T>(_ observer: T) where T: CardDeckViewObserver, T.ContentView == ContentView {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: CardDeckViewObserver, T.ContentView == ContentView {
		observers.remove(.init(wrapping: observer))
	}

	public func scrollToPosition(_ position: CGFloat, animated: Bool) {
		scrollPosition = position
		scrollView.setContentOffset(.init(
			x: orientational(vertical: scrollView.contentOffset.x, horizontal: scrollContentOffset(for: position)),
			y: orientational(vertical: scrollContentOffset(for: position), horizontal: scrollView.contentOffset.y)
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

	private func scrollContentOffset(for position: CGFloat) -> CGFloat {
		let directionMultiplier: CGFloat
		switch orientation {
		case .leftToRight, .topToBottom:
			directionMultiplier = -1
		case .rightToLeft, .bottomToTop:
			directionMultiplier = 1
		}
		return calculatedScrollLayout!.itemScrollLength * position * directionMultiplier
	}

	private func scrollPositionForContentOffset(_ contentOffset: CGFloat) -> CGFloat {
		let directionMultiplier: CGFloat
		switch orientation {
		case .leftToRight, .topToBottom:
			directionMultiplier = -1
		case .rightToLeft, .bottomToTop:
			directionMultiplier = 1
		}
		return contentOffset / calculatedScrollLayout!.itemScrollLength * directionMultiplier
	}

	private func updateLayoutIfNeeded() {
		guard isDirty else { return }
		updateLayout()
	}

	private func updateLayout() {
		isDirty = false

		cleanUpEntryViews(andUpdateLayout: false)
		recalculateLayout()
	}

	private func recalculateLayout() {
		let scrollPositionWasAtEnd = scrollPositionIsAtEnd
		let visibleEntryViews = self.visibleEntryViews
		visibleEntryViews.forEach { $0.superview!.bringSubviewToFront($0) }
		calculatedStaticLayout = calculateStaticLayout()
		recalculateScrollLayout()

		if scrollPositionWasAtEnd && abs(scrollPosition) > 0.005 {
			scrollToPosition(CGFloat(visibleEntryViews.count), animated: false)
		} else {
			scrollToPosition(scrollPosition, animated: false)
		}
	}

	private func recalculateScrollLayout() {
		let visibleEntryViews = self.visibleEntryViews
		let scrollLayout = calculateScrollLayout()
		calculatedScrollLayout = scrollLayout

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
			constraints += entryView.ratio(size: .init(width: max(itemSize.width, 1), height: max(itemSize.height, 1)))

			let position: CGFloat
			if visibleEntryViews.count == 1 {
				position = scrollLayout.firstGroupStart
			} else {
				let itemIndexFraction = visibleEntryViews.count == 1 ? 0 : CGFloat(index) / max(CGFloat(visibleEntryViews.count - 1), 1)
				let firstPosition = scrollLayout.firstGroupStart + (abs(scrollLayout.firstGroupLength) - scrollLayout.staticLayout.itemLength) * itemIndexFraction
				let secondPosition = scrollLayout.secondGroupStart + (abs(scrollLayout.secondGroupLength) - scrollLayout.staticLayout.itemLength) * itemIndexFraction
				let fraction = (scrollLayout.mappedScrollPosition - CGFloat(visibleEntryViews.count - 1) + CGFloat(index)).clamped(to: 0 ... 1)
				position = firstPosition + (secondPosition - firstPosition) * fraction
			}

			switch orientation {
			case .leftToRight:
				constraints += entryView.leftToSuperview(inset: position.isNaN ? 0 : position - scrollLayout.firstGroupStart + contentInsets.left)
			case .rightToLeft:
				constraints += entryView.rightToSuperview(inset: position.isNaN ? 0 : position - scrollLayout.firstGroupStart + contentInsets.right)
			case .topToBottom:
				constraints += entryView.topToSuperview(inset: position.isNaN ? 0 : position - scrollLayout.firstGroupStart + contentInsets.top)
			case .bottomToTop:
				constraints += entryView.bottomToSuperview(inset: position.isNaN ? 0 : position - scrollLayout.firstGroupStart + contentInsets.bottom)
			}

			let previousConstraints = entryView.entryConstraints.sorted(by: \.firstAttribute.rawValue, .ascending, then: \.secondAttribute.rawValue, .ascending)
			let newConstraints = constraints.sorted(by: \.firstAttribute.rawValue, .ascending, then: \.secondAttribute.rawValue, .ascending)
			var shouldUpdateConstraints = previousConstraints.count != newConstraints.count
			if !shouldUpdateConstraints {
				for constraintIndex in newConstraints.indices {
					let previousConstraint = previousConstraints[constraintIndex]
					let newConstraint = newConstraints[constraintIndex]
					if previousConstraint.firstAttribute != newConstraint.firstAttribute || previousConstraint.secondAttribute != newConstraint.secondAttribute || previousConstraint.multiplier != newConstraint.multiplier || previousConstraint.constant != newConstraint.constant {
						shouldUpdateConstraints = true
						break
					}
				}
			}
			if shouldUpdateConstraints {
				entryView.entryConstraints = constraints
			}
		}

		let scrollableContentLength = CGFloat(visibleEntryViews.count) * scrollLayout.itemScrollLength
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

	private func calculateStaticLayout() -> CalculatedStaticLayout {
		let visibleEntryViews = self.visibleEntryViews
		let itemSize = self.itemSize
		let itemLength = orientational(itemSize, vertical: \.height, horizontal: \.width)
		let collectionViewLength = orientational(frame, vertical: \.height, horizontal: \.width)
		let workingLength = collectionViewLength - orientational(contentInsets, vertical: \.vertical, horizontal: \.horizontal)

		let minL = orientational(contentInsets, vertical: \.top, horizontal: \.left)
		let maxL = orientational(
			vertical: frame.height - contentInsets.bottom,
			horizontal: frame.width - contentInsets.right
		)

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
			firstGroupStart = minL
		case .rightToLeft, .bottomToTop:
			firstGroupStart = maxL
		}
		firstGroupEnd = firstGroupStart + workingLength - itemLength - splitSpacing
		let baseSpacing = (firstGroupLength - itemLength) / max(CGFloat(visibleEntryViews.count - 2), 1)
		firstGroupEnd += baseSpacing

		secondGroupEnd = firstGroupStart + workingLength
		secondGroupStart = secondGroupEnd - firstGroupLength

		if let maxGroupedSpacing = maxGroupedSpacing {
			let currentSpacing = (abs(firstGroupLength) - itemLength) / max(CGFloat(visibleEntryViews.count - 1), 1)
			if maxGroupedSpacing < currentSpacing {
				let newGroupLength = maxGroupedSpacing * CGFloat(visibleEntryViews.count - 1) + itemLength
				firstGroupEnd = firstGroupStart + newGroupLength
				secondGroupStart = secondGroupEnd - newGroupLength
			}
		}

		switch splitCardGroupPosition {
		case .near:
			let currentSpacing = (abs(firstGroupLength) - itemLength) / max(CGFloat(visibleEntryViews.count - 1), 1)
			secondGroupEnd = firstGroupEnd + (splitSpacing + itemLength - currentSpacing)
			secondGroupStart = secondGroupEnd - firstGroupLength
		case .far:
			break
		}

		return .init(
			itemSize: itemSize,
			itemLength: itemLength,
			collectionViewLength: collectionViewLength,
			workingLength: workingLength,
			firstGroupStart: firstGroupStart,
			firstGroupEnd: firstGroupEnd,
			secondGroupStart: secondGroupStart,
			secondGroupEnd: secondGroupEnd
		)
	}

	private func calculateScrollLayout() -> CalculatedScrollLayout {
		let staticLayout = calculatedStaticLayout!
		let visibleEntryViews = self.visibleEntryViews
		let baseScrollPosition = orientational(scrollView.contentOffset, vertical: \.y, horizontal: \.x)
		let mirroredIfNeededScrollPosition: CGFloat
		switch orientation {
		case .leftToRight, .topToBottom:
			mirroredIfNeededScrollPosition = -baseScrollPosition
		case .rightToLeft, .bottomToTop:
			mirroredIfNeededScrollPosition = baseScrollPosition
		}

		let firstGroupStart = staticLayout.firstGroupStart
		var firstGroupEnd = staticLayout.firstGroupEnd
		var secondGroupStart = staticLayout.secondGroupStart
		let secondGroupEnd = staticLayout.secondGroupEnd

		var firstGroupLength: CGFloat {
			return firstGroupEnd - firstGroupStart
		}
		var secondGroupLength: CGFloat {
			return secondGroupEnd - secondGroupStart
		}

		let itemScrollLength = abs(secondGroupStart - firstGroupStart)
		let mappedScrollPosition = mirroredIfNeededScrollPosition / itemScrollLength
		let firstPositionMultiplier = mappedScrollPosition < 0 ? 1 / (abs(mappedScrollPosition) + 1) : 1
		let secondPositionMultiplier = mappedScrollPosition > CGFloat(visibleEntryViews.count) ? 1 / (abs(mappedScrollPosition - CGFloat(visibleEntryViews.count)) + 1) : 1

		let newFirstGroupLength = (abs(firstGroupLength) - staticLayout.itemLength) * firstPositionMultiplier + staticLayout.itemLength
		firstGroupEnd = firstGroupStart + newFirstGroupLength
		let newSecondGroupLength = (abs(secondGroupLength) - staticLayout.itemLength) * secondPositionMultiplier + staticLayout.itemLength
		secondGroupStart = secondGroupEnd - newSecondGroupLength

		return .init(
			staticLayout: staticLayout,
			itemScrollLength: itemScrollLength,
			mappedScrollPosition: mappedScrollPosition,
			firstGroupEnd: firstGroupEnd,
			secondGroupStart: secondGroupStart
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
			if oldFrame.size == newFrame.size { return }
			parent.recalculateLayout()
			parent.scrollToPosition(parent.scrollPosition, animated: false)
		}

		func scrollViewDidScroll(_ scrollView: UIScrollView) {
			guard let parent = parent else { return }
			parent.recalculateScrollLayout()
			let contentOffset = parent.orientational(scrollView.contentOffset, vertical: \.y, horizontal: \.x)
			let position = parent.scrollPositionForContentOffset(contentOffset)
			parent.observers.forEach { $0.didScroll(to: position, in: parent) }
		}

		func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
			guard let parent = parent else { return }
			if !parent.scrollingLocksOntoItems {
				let scrollPosition: CGFloat
				switch parent.orientation {
				case .leftToRight, .rightToLeft:
					scrollPosition = parent.scrollPositionForContentOffset(targetContentOffset.pointee.x)
				case .topToBottom, .bottomToTop:
					scrollPosition = parent.scrollPositionForContentOffset(targetContentOffset.pointee.y)
				}
				parent.scrollPosition = scrollPosition
				parent.observers.forEach { $0.didEndDragging(targetPosition: scrollPosition, in: parent) }
				return
			}

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

			let itemScrollLength = parent.calculatedScrollLayout!.itemScrollLength
			targetPosition = round(targetPosition / itemScrollLength) * itemScrollLength
			switch parent.orientation {
			case .leftToRight, .rightToLeft:
				targetContentOffset.pointee.x = targetPosition
			case .topToBottom, .bottomToTop:
				targetContentOffset.pointee.y = targetPosition
			}

			let scrollPosition = parent.scrollPositionForContentOffset(targetPosition)
			parent.scrollPosition = scrollPosition
			parent.observers.forEach { $0.didEndDragging(targetPosition: scrollPosition, in: parent) }
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
				$0.scrollToPosition(3, animated: false)
			}
		}
	}
}
#endif
#endif
