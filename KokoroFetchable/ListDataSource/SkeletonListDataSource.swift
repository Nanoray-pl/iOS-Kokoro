//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public struct SkeletonListDataSourceBehavior {
	/// Amount of skeleton cells to be used initially before any data is fetched.
	let initialSkeletonCount: Int

	/// Amount of skeleton cells to be used additionally when an extra page is requested and being fetched.
	let additionalSkeletonCount: Int
}

public enum SkeletonListDataSourceElement<WrappedType> {
	case skeleton
	case element(_ element: WrappedType)
}

extension SkeletonListDataSourceElement: Equatable where WrappedType: Equatable {}
extension SkeletonListDataSourceElement: Hashable where WrappedType: Hashable {}

public class SkeletonListDataSource<Wrapped: FetchableListDataSource>: FetchableListDataSource {
	public typealias Element = SkeletonListDataSourceElement<Wrapped.Element>

	private let wrapped: Wrapped
	private let behavior: SkeletonListDataSourceBehavior
	private lazy var observer = WrappedObserver(parent: self)
	private var observers = [WeakFetchableListDataSourceObserver<Element>]()

	private var skeletonCount: Int {
		switch (isFetching: wrapped.isFetching, count: wrapped.count) {
		case (isFetching: false, _):
			return 0
		case (isFetching: true, count: 0):
			return behavior.initialSkeletonCount
		case (isFetching: true, _):
			return behavior.additionalSkeletonCount
		}
	}

	public var elements: [Element] {
		return wrapped.elements.map { .element($0) } + (0 ..< skeletonCount).map { _ in .skeleton }
	}

	public var count: Int {
		return wrapped.count + skeletonCount
	}

	public var error: Error? {
		return wrapped.error
	}

	public var isFetching: Bool {
		return wrapped.isFetching
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
		observers.append(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		let identifier = ObjectIdentifier(observer)
		observers.removeFirst(where: { $0.identifier == identifier })
	}

	private func updateData() {
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers = observers.filter { $0.weakReference != nil }
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private unowned let parent: SkeletonListDataSource<Wrapped>

		init(parent: SkeletonListDataSource<Wrapped>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Wrapped.Element>) {
			parent.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func withSkeletons(behavior: SkeletonListDataSourceBehavior) -> SkeletonListDataSource<Self> {
		return SkeletonListDataSource(wrapping: self, behavior: behavior)
	}
}
