//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public enum SkeletonListDataSourceBehaviorCount: ExpressibleByIntegerLiteral {
	case fixed(_ count: Int)
	case dynamic(_ closure: (_ itemCount: Int) -> Int)

	public init(integerLiteral value: IntegerLiteralType) {
		self = .fixed(value)
	}
}

public struct SkeletonListDataSourceBehavior {
	/// Amount of skeleton cells to be used initially before any data is fetched.
	let initialSkeletonCount: SkeletonListDataSourceBehaviorCount

	/// Amount of skeleton cells to be used additionally when an extra page is requested and being fetched.
	let additionalSkeletonCount: SkeletonListDataSourceBehaviorCount

	public init(initialSkeletonCount: SkeletonListDataSourceBehaviorCount, additionalSkeletonCount: SkeletonListDataSourceBehaviorCount) {
		self.initialSkeletonCount = initialSkeletonCount
		self.additionalSkeletonCount = additionalSkeletonCount
	}
}

public protocol SkeletonListDataSourceElementProtocol {
	associatedtype WrappedType

	func skeletonListDataSourceElement() -> SkeletonListDataSourceElement<WrappedType>
}

public enum SkeletonListDataSourceElement<WrappedType>: SkeletonListDataSourceElementProtocol {
	case skeleton
	case element(_ element: WrappedType)

	public func skeletonListDataSourceElement() -> SkeletonListDataSourceElement<WrappedType> {
		return self
	}
}

extension SkeletonListDataSourceElement: Equatable where WrappedType: Equatable {}
extension SkeletonListDataSourceElement: Hashable where WrappedType: Hashable {}

/// A `FetchableListDataSource` implementation which adds additional "skeleton" elements to the data source it is wrapping while it is in the fetching state.
public class SkeletonListDataSource<Wrapped: FetchableListDataSource>: FetchableListDataSource {
	public typealias Element = SkeletonListDataSourceElement<Wrapped.Element>

	private let wrapped: Wrapped
	private let behavior: SkeletonListDataSourceBehavior
	private lazy var observer = WrappedObserver(parent: self)

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	private var skeletonCount: Int {
		switch (isFetching: wrapped.isFetching, isAfterInitialFetch: wrapped.isAfterInitialFetch) {
		case (isFetching: false, _):
			return 0
		case (isFetching: true, isAfterInitialFetch: false):
			switch behavior.initialSkeletonCount {
			case let .fixed(count):
				return count
			case let .dynamic(closure):
				return closure(wrapped.count)
			}
		case (isFetching: true, isAfterInitialFetch: true):
			switch behavior.additionalSkeletonCount {
			case let .fixed(count):
				return count
			case let .dynamic(closure):
				return closure(wrapped.count)
			}
		}
	}

	public var elements: [Element] {
		return wrapped.elements.map { .element($0) } + (0 ..< skeletonCount).map { _ in .skeleton }
	}

	public var count: Int {
		return wrapped.count + skeletonCount
	}

	public var expectedTotalCount: Int? {
		return wrapped.expectedTotalCount
	}

	public var error: Error? {
		return wrapped.error
	}

	public var isEmpty: Bool {
		return wrapped.isEmpty && skeletonCount == 0
	}

	public var isFetching: Bool {
		return wrapped.isFetching
	}

	public var isAfterInitialFetch: Bool {
		return wrapped.isAfterInitialFetch
	}

	public init(wrapping wrapped: Wrapped, behavior: SkeletonListDataSourceBehavior) {
		self.wrapped = wrapped
		self.behavior = behavior
		wrapped.addObserver(observer)
	}

	deinit {
		wrapped.removeObserver(observer)
	}

	public subscript(index: Int) -> Element {
		if index < wrapped.count {
			return .element(wrapped[index])
		} else if index < wrapped.count + skeletonCount {
			return .skeleton
		} else {
			fatalError("Index out of bounds")
		}
	}

	public func reset() {
		wrapped.reset()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		if isFetching { return false }

		if wrapped.fetchAdditionalData() {
			updateData()
			return true
		} else {
			return false
		}
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.remove(withIdentity: ObjectIdentifier(observer))
	}

	private func updateData() {
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: SkeletonListDataSource<Wrapped>?

		init(parent: SkeletonListDataSource<Wrapped>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Wrapped.Element>) {
			parent?.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func withSkeletons(behavior: SkeletonListDataSourceBehavior) -> SkeletonListDataSource<Self> {
		return SkeletonListDataSource(wrapping: self, behavior: behavior)
	}
}

public extension Sequence where Element: SkeletonListDataSourceElementProtocol {
	func filterNonSkeleton() -> [Element.WrappedType] {
		var results = [Element.WrappedType]()
		forEach {
			switch $0.skeletonListDataSourceElement() {
			case let .element(element):
				results.append(element)
			case .skeleton:
				break
			}
		}
		return results
	}
}
