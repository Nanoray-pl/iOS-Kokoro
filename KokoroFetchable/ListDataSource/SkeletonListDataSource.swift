//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

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

public class SkeletonListDataSource<WrappedType>: FetchableListDataSource {
	public typealias Element = SkeletonListDataSourceElement<WrappedType>

	private let wrapped: AnyFetchableListDataSource<WrappedType>
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

	public init<T>(wrapping wrapped: T, behavior: SkeletonListDataSourceBehavior) where T: FetchableListDataSource, T.Element == WrappedType {
		self.wrapped = wrapped.eraseToAnyFetchableListDataSource()
		self.behavior = behavior
		wrapped.addObserver(observer)
	}

	deinit {
		wrapped.removeObserver(observer)
	}

	public subscript(index: Int) -> SkeletonListDataSourceElement<WrappedType> {
		if index < wrapped.count {
			return .element(wrapped[index])
		} else if index < wrapped.count + skeletonCount {
			return .skeleton
		} else {
			fatalError("Index out of bounds")
		}
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
		if let index = observers.firstIndex(where: { $0.identifier == identifier }) {
			observers.remove(at: index)
		}
	}

	private func updateData() {
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers = observers.filter { $0.weakReference != nil }
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		typealias Element = WrappedType

		private unowned let parent: SkeletonListDataSource<WrappedType>

		init(parent: SkeletonListDataSource<WrappedType>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<WrappedType>) {
			parent.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func withSkeletons(behavior: SkeletonListDataSourceBehavior) -> SkeletonListDataSource<Element> {
		return SkeletonListDataSource(wrapping: self, behavior: behavior)
	}
}
