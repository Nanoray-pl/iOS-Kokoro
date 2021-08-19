//
//  Created on 23/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

/// A `UIStackView`-like view, which automatically adds separators between its arranged subviews, which can either be fixed size or dynamically sized via Auto Layout.
public class SeparatorStackView<ContentView: UIView>: UIView {
	public enum SeparatorLength: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral, Hashable {
		case fixed(_ points: CGFloat)
		case dynamic

		public init(integerLiteral value: IntegerLiteralType) {
			self = .fixed(CGFloat(value))
		}

		public init(floatLiteral value: FloatLiteralType) {
			self = .fixed(CGFloat(value))
		}
	}

	public enum Distribution {
		case fill, fillEqually
	}

	private class EntryView: UIView, UIViewSubviewObserver {
		private unowned let owner: SeparatorStackView
		let contentView: ContentView
		weak var separatorView: UIView?
		var customSeparatorLength: SeparatorLength?
		private let observation: NSKeyValueObservation

		private(set) var stackView: UIStackView!

		init(with contentView: ContentView, observation: NSKeyValueObservation, owner: SeparatorStackView) {
			self.owner = owner
			self.contentView = contentView
			self.observation = observation
			super.init(frame: .zero)
			buildUI()
		}

		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		private func buildUI() {
			let constraints = ConstraintSession.current

			stackView = UIStackView().with { [parent = self] in
				$0.addSubviewObserver(self)
				$0.addArrangedSubview(contentView)

				parent.addSubview($0)
				constraints += $0.edgesToSuperview()
			}
		}

		deinit {
			stackView.removeSubviewObserver(self)
		}

		func update() {
			isHidden = contentView.isHidden
			separatorView?.removeFromSuperview()
			if !isHidden && owner.entryViews.last(where: { !$0.contentView.isHidden }) != self {
				let index = owner.entryViews.firstIndex(of: self)!
				if owner.entryViews.count <= index + 1 { return }

				let nextEntryView = owner.entryViews[index + 1]
				let separatorView = owner.separatorBuilder(contentView, nextEntryView.contentView)
				stackView.addArrangedSubview(separatorView)
				self.separatorView = separatorView

				let separatorLength = customSeparatorLength ?? owner.separatorLength
				switch separatorLength {
				case let .fixed(points):
					switch stackView.axis {
					case .horizontal:
						separatorView.width(of: points).activate()
					case .vertical:
						separatorView.height(of: points).activate()
					@unknown default:
						fatalError("Unknown axis \(stackView.axis)")
					}
				case .dynamic:
					break
				}
			}
		}

		func didAddSubview(_ subview: UIView, to view: UIView) {
			// do nothing
		}

		func didRemoveSubview(_ subview: UIView, from view: UIView) {
			if subview == contentView {
				owner.removeArrangedSubview(contentView)
			}
		}
	}

	public var separatorBuilder: (_ previousView: ContentView, _ nextView: ContentView) -> UIView = { _, _ in UIView() } {
		didSet {
			queueSeparatorUpdate()
		}
	}

	public var axis: NSLayoutConstraint.Axis {
		get {
			return stackView.axis
		}
		set {
			guard newValue != stackView.axis else { return }
			stackView.axis = newValue
			entryViews.forEach { $0.stackView.axis = newValue }
			queueSeparatorUpdate()
		}
	}

	@Proxy(\.stackView.alignment)
	public var alignment: UIStackView.Alignment

	var distribution = Distribution.fill {
		didSet {
			guard distribution != oldValue else { return }
			queueSeparatorUpdate()
		}
	}

	public var separatorLength: SeparatorLength = 0 {
		didSet {
			guard separatorLength != oldValue else { return }
			queueSeparatorUpdate()
		}
	}

	@Proxy(\.stackView.insetsLayoutMarginsFromSafeArea)
	public var insetsContentLayoutMarginsFromSafeArea: Bool

	@Proxy(\.stackView.isLayoutMarginsRelativeArrangement)
	public var isContentLayoutMarginsRelativeArrangement: Bool

	@Proxy(\.stackView.layoutMargins)
	public var contentLayoutMargins: UIEdgeInsets

	public var arrangedSubviews: [ContentView] {
		return entryViews.map(\.contentView)
	}

	private var entryViews = [EntryView]()

	private var stackView: UIStackView!

	private var isSeparatorUpdateQueued = false

	private var distributionConstraints = [NSLayoutConstraint]() {
		didSet {
			oldValue.deactivate()
			distributionConstraints.activate()
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
		let constraints = ConstraintSession.current

		stackView = UIStackView().with { [parent = self] in
			$0.isLayoutMarginsRelativeArrangement = true
			$0.insetsLayoutMarginsFromSafeArea = false
			parent.addSubview($0)
			constraints += $0.edgesToSuperview()
		}
	}

	public func addArrangedSubview(_ view: ContentView) {
		insertArrangedSubview(view, at: entryViews.count)
	}

	public func insertArrangedSubview(_ view: ContentView, at index: Int) {
		let observation = view.observe(\.isHidden) { [weak self] _, _ in
			self?.queueSeparatorUpdate()
		}
		let entryView = EntryView(with: view, observation: observation, owner: self)
		entryView.stackView.axis = axis
		stackView.addArrangedSubview(entryView)
		entryViews.insert(entryView, at: index)
		queueSeparatorUpdate()
	}

	public func removeArrangedSubview(_ view: ContentView) {
		guard let index = entryViews.firstIndex(where: { $0.contentView == view }) else { return }
		let entryView = entryViews[index]
		entryViews.remove(at: index)
		stackView.removeArrangedSubview(entryView)
		queueSeparatorUpdate()
	}

	public func setCustomSeparatorLength(_ separatorLength: SeparatorLength?, after view: ContentView) {
		guard let index = entryViews.firstIndex(where: { $0.contentView == view }) else { return }
		let entryView = entryViews[index]
		if entryView.customSeparatorLength != separatorLength {
			entryView.customSeparatorLength = separatorLength
			entryView.update()
		}
	}

	private func updateDistributionConstraints() {
		switch distribution {
		case .fill:
			distributionConstraints = []
		case .fillEqually:
			if entryViews.count > 1 {
				switch axis {
				case .horizontal:
					distributionConstraints = (1 ..< entryViews.count).map { entryViews[$0].contentView.width(to: entryViews[$0 - 1].contentView) }
				case .vertical:
					distributionConstraints = (1 ..< entryViews.count).map { entryViews[$0].contentView.height(to: entryViews[$0 - 1].contentView) }
				@unknown default:
					fatalError("Unknown axis \(stackView.axis)")
				}
			} else {
				distributionConstraints = []
			}
		}
	}

	private func queueSeparatorUpdate() {
		if isSeparatorUpdateQueued { return }
		isSeparatorUpdateQueued = true
		DispatchQueue.main.async {
			self.updateSeparatorsNow()
		}
	}

	private func updateSeparatorsNow() {
		isSeparatorUpdateQueued = false
		entryViews.forEach { $0.update() }
	}
}
#endif
