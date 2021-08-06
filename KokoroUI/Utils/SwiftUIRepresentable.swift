//
//  Created on 11/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(CoreGraphics) && canImport(Foundation)
import CoreGraphics
import Foundation

public enum XcodePreviews {
	public static var isPreviewing: Bool {
		#if canImport(SwiftUI) && DEBUG
		return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
		#else
		return false
		#endif
	}
}

#if canImport(UIKit) && canImport(SwiftUI) && DEBUG
import SwiftUI
import UIKit

public func representable<T: UIViewController>(factory: @escaping () -> T) -> some View {
	return ViewControllerRepresentable(factory: factory)
		.edgesIgnoringSafeArea(.all)
}

public func representable<T: UIView>(size: ViewRepresentableSize, forceLayout: Bool = false, factory: @escaping () -> T) -> some View {
	return ViewRepresentable(size: size, forceLayout: forceLayout, factory: factory)
		.previewLayout(.sizeThatFits)
}

public func representable<T: UIView>(width: ViewRepresentableSingleSize, height: ViewRepresentableSingleSize, forceLayout: Bool = false, factory: @escaping () -> T) -> some View {
	return representable(size: .init(width: width, height: height), forceLayout: forceLayout, factory: factory)
}

private struct ViewControllerRepresentable<T: UIViewController>: UIViewControllerRepresentable {
	typealias UIViewControllerType = T

	private let factory: () -> T

	init(factory: @escaping () -> T) {
		self.factory = factory
	}

	func makeUIViewController(context: UIViewControllerRepresentableContext<ViewControllerRepresentable<T>>) -> T {
		return factory()
	}

	func updateUIViewController(_ uiViewController: T, context: UIViewControllerRepresentableContext<ViewControllerRepresentable<T>>) {}
}

public struct ViewRepresentableSize: Hashable {
	public let width: ViewRepresentableSingleSize
	public let height: ViewRepresentableSingleSize

	public static let device = ViewRepresentableSize(width: .device, height: .device)
	public static let compressed = ViewRepresentableSize(width: .compressed, height: .compressed)
}

extension ViewRepresentableSize {
	init(size: CGSize) {
		width = .fixed(size.width)
		height = .fixed(size.height)
	}
}

public enum ViewRepresentableSingleSize: Hashable {
	case device, compressed
	case fixed(_ length: CGFloat)
}

private struct ViewRepresentable<T: UIView>: UIViewRepresentable {
	typealias UIViewType = Container

	private let size: ViewRepresentableSize
	private let forceLayout: Bool
	private let factory: () -> T

	init(size: ViewRepresentableSize = .device, forceLayout: Bool = false, factory: @escaping () -> T) {
		self.size = size
		self.forceLayout = forceLayout
		self.factory = factory
	}

	func makeUIView(context: UIViewRepresentableContext<ViewRepresentable<T>>) -> Container {
		return Container(wrapping: factory(), size: size, forceLayout: forceLayout)
	}

	func updateUIView(_ uiView: Container, context: UIViewRepresentableContext<ViewRepresentable<T>>) {
		uiView.recalculateSize()
	}

	class Container: UIView {
		private let size: ViewRepresentableSize
		private let forceLayout: Bool
		private let wrapped: UIView

		private var calculatedSizeStorage: CGSize?

		private var calculatedSize: CGSize {
			if let calculatedSize = calculatedSizeStorage {
				return calculatedSize
			} else {
				sizeConstraints = []

				let horizontalPriority: UILayoutPriority
				let fittingWidth: CGFloat
				switch size.width {
				case .device:
					horizontalPriority = .required
					fittingWidth = (window?.bounds ?? UIScreen.main.bounds).width
				case .compressed:
					horizontalPriority = .fittingSizeLevel
					fittingWidth = UIView.layoutFittingCompressedSize.width
				case let .fixed(length):
					horizontalPriority = .required
					fittingWidth = length
					sizeConstraints += width(of: length)
				}

				let verticalPriority: UILayoutPriority
				let fittingHeight: CGFloat
				switch size.height {
				case .device:
					verticalPriority = .required
					fittingHeight = (window?.bounds ?? UIScreen.main.bounds).height
				case .compressed:
					verticalPriority = .fittingSizeLevel
					fittingHeight = UIView.layoutFittingCompressedSize.height
				case let .fixed(length):
					verticalPriority = .required
					fittingHeight = length
					sizeConstraints += height(of: length)
				}

				if forceLayout {
					var allViews = [UIView]()
					var viewsToCheck: [UIView] = [self]
					while let nextView = viewsToCheck.first {
						viewsToCheck.removeFirst()
						allViews.append(nextView)
						viewsToCheck.append(contentsOf: nextView.subviews)
					}
					allViews.reversed().forEach { $0.layoutIfNeeded() }
				} else {
					setNeedsLayout()
					layoutIfNeeded()
				}

				let calculatedSize = wrapped.systemLayoutSizeFitting(.init(width: fittingWidth, height: fittingHeight), withHorizontalFittingPriority: horizontalPriority, verticalFittingPriority: verticalPriority)
				calculatedSizeStorage = calculatedSize
				sizeConstraints = size(of: calculatedSize)
				return calculatedSize
			}
		}

		override var intrinsicContentSize: CGSize {
			return calculatedSize
		}

		private var sizeConstraints = [NSLayoutConstraint]() {
			didSet {
				oldValue.deactivate()
				sizeConstraints.activate()
			}
		}

		init(wrapping view: UIView, size: ViewRepresentableSize, forceLayout: Bool = false) {
			self.wrapped = view
			self.size = size
			self.forceLayout = forceLayout
			super.init(frame: .zero)
			addSubview(view)
			view.edgesToSuperview().activate()
			[view, self].forEach {
				$0.setContentHuggingPriority(.required, for: .vertical)
				$0.setContentHuggingPriority(.required, for: .horizontal)
				$0.setContentCompressionResistancePriority(.required, for: .vertical)
				$0.setContentCompressionResistancePriority(.required, for: .horizontal)
			}
			recalculateSize()
		}

		override func didMoveToWindow() {
			super.didMoveToWindow()
			recalculateSize()
		}

		fileprivate func recalculateSize() {
			calculatedSizeStorage = nil
			invalidateIntrinsicContentSize()
			_ = calculatedSize
		}

		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}

final class TableRepresentable<Item, Cell: UITableViewCell>: NSObject, UIViewRepresentable, UITableViewDataSource {
	typealias UIViewType = UITableView

	private let reuseIdentifier = "Cell"

	private let items: [Item]
	private let rowHeight: CGFloat
	private let configurator: (_ cell: Cell, _ item: Item) -> Void

	init(items: [Item], rowHeight: CGFloat = 44, configurator: @escaping (_ cell: Cell, _ item: Item) -> Void) {
		self.items = items
		self.rowHeight = rowHeight
		self.configurator = configurator
	}

	func makeUIView(context: UIViewRepresentableContext<TableRepresentable<Item, Cell>>) -> UITableView {
		return UITableView(frame: .zero, style: .plain).with {
			$0.rowHeight = rowHeight
			$0.dataSource = self
			$0.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
		}
	}

	func updateUIView(_ uiView: UITableView, context: UIViewRepresentableContext<TableRepresentable<Item, Cell>>) {
		uiView.setContentHuggingPriority(.required, for: .vertical)
		uiView.setContentHuggingPriority(.required, for: .horizontal)
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! Cell).with {
			configurator($0, items[indexPath.row])
		}
	}
}
#endif
#endif
