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
	return ViewControllerRepresentable(factory: factory).edgesIgnoringSafeArea(.all)
}

public func representable<T: UIView>(size: ViewRepresentableSize = .intrinsic, factory: @escaping () -> T) -> some View {
	return ViewRepresentable(size: size, factory: factory).previewLayout(.sizeThatFits)
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
	public static let intrinsic = ViewRepresentableSize(width: .intrinsic, height: .intrinsic)
	public static let compressed = ViewRepresentableSize(width: .compressed, height: .compressed)

	public let width: ViewRepresentableSingleSize
	public let height: ViewRepresentableSingleSize

	public init(width: ViewRepresentableSingleSize, height: ViewRepresentableSingleSize) {
		self.width = width
		self.height = height
	}

	public init(size: CGSize) {
		width = .fixed(size.width)
		height = .fixed(size.height)
	}
}

public enum ViewRepresentableSingleSize: Hashable {
	case intrinsic, compressed
	case fixed(_ length: CGFloat)
}

private struct ViewRepresentable<T: UIView>: UIViewRepresentable {
	typealias UIViewType = UIView

	private let size: ViewRepresentableSize
	private let factory: () -> T

	init(size: ViewRepresentableSize = .intrinsic, factory: @escaping () -> T) {
		self.size = size
		self.factory = factory
	}

	func makeUIView(context: UIViewRepresentableContext<ViewRepresentable<T>>) -> UIView {
		return Container(wrapping: factory(), size: size)
	}

	func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<ViewRepresentable<T>>) {
		uiView.setContentHuggingPriority(.required, for: .vertical)
		uiView.setContentHuggingPriority(.required, for: .horizontal)
	}

	private class Container: UIView {
		private let size: ViewRepresentableSize
		private let wrapped: UIView

		override var intrinsicContentSize: CGSize {
			let intrinsicSize = super.intrinsicContentSize
			let compressedSize = wrapped.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize, withHorizontalFittingPriority: .defaultLow, verticalFittingPriority: .defaultLow)

			let width: CGFloat
			switch size.width {
			case .intrinsic:
				width = intrinsicSize.width
			case .compressed:
				width = compressedSize.width
			case let .fixed(length):
				width = length
			}

			let height: CGFloat
			switch size.height {
			case .intrinsic:
				height = intrinsicSize.height
			case .compressed:
				height = compressedSize.height
			case let .fixed(length):
				height = length
			}

			return CGSize(width: width, height: height)
		}

		init(wrapping view: UIView, size: ViewRepresentableSize) {
			self.size = size
			self.wrapped = view
			super.init(frame: .zero)
			addSubview(view)
			view.edgesToSuperview().activate()
		}

		override func didMoveToSuperview() {
			super.didMoveToSuperview()

			if case let .fixed(length) = size.width {
				wrapped.width(of: length).activate()
			}
			if case let .fixed(length) = size.height {
				wrapped.height(of: length).activate()
			}

			switch (size.width, size.height) {
			case (.compressed, _), (_, .compressed):
				layoutIfNeeded()
			default:
				break
			}
		}

		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}

public final class TableRepresentable<Item, Cell: UITableViewCell>: NSObject, UIViewRepresentable, UITableViewDataSource {
	public typealias UIViewType = UITableView

	private let reuseIdentifier = "Cell"

	private let items: [Item]
	private let rowHeight: CGFloat
	private let configurator: (_ cell: Cell, _ item: Item) -> Void

	public init(items: [Item], rowHeight: CGFloat = 44, configurator: @escaping (_ cell: Cell, _ item: Item) -> Void) {
		self.items = items
		self.rowHeight = rowHeight
		self.configurator = configurator
	}

	public func makeUIView(context: UIViewRepresentableContext<TableRepresentable<Item, Cell>>) -> UITableView {
		return UITableView(frame: .zero, style: .plain).with {
			$0.rowHeight = rowHeight
			$0.dataSource = self
			$0.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
		}
	}

	public func updateUIView(_ uiView: UITableView, context: UIViewRepresentableContext<TableRepresentable<Item, Cell>>) {
		uiView.setContentHuggingPriority(.required, for: .vertical)
		uiView.setContentHuggingPriority(.required, for: .horizontal)
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! Cell).with {
			configurator($0, items[indexPath.row])
		}
	}
}
#endif
#endif
