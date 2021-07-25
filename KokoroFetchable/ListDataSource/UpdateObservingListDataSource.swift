//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public class UpdateObservingListDataSource<Wrapped: FetchableListDataSource>: FetchableListDataSource {
	public typealias Element = Wrapped.Element

	private let wrapped: Wrapped
	private let closure: (_ dataSource: AnyFetchableListDataSource<Element>) -> Void
	private lazy var observer = WrappedObserver(parent: self)

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	public var elements: [Element] {
		return wrapped.elements
	}

	public var count: Int {
		return wrapped.count
	}

	public var expectedTotalCount: Int? {
		return wrapped.expectedTotalCount
	}

	public var error: Error? {
		return wrapped.error
	}

	public var isEmpty: Bool {
		return wrapped.isEmpty
	}

	public var isFetching: Bool {
		return wrapped.isFetching
	}

	public var isAfterInitialFetch: Bool {
		return wrapped.isAfterInitialFetch
	}

	public subscript(_ index: Int) -> Element {
		return wrapped[index]
	}

	public init(wrapping wrapped: Wrapped, closure: @escaping (_ dataSource: AnyFetchableListDataSource<Element>) -> Void) {
		self.wrapped = wrapped
		self.closure = closure
		wrapped.addObserver(observer)
	}

	deinit {
		wrapped.removeObserver(observer)
	}

	public func reset() {
		wrapped.reset()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return wrapped.fetchAdditionalData()
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.remove(withIdentity: ObjectIdentifier(observer))
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: UpdateObservingListDataSource<Wrapped>?

		init(parent: UpdateObservingListDataSource<Wrapped>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			guard let parent = parent else { return }
			let erasedParent = parent.eraseToAnyFetchableListDataSource()
			parent.closure(erasedParent)
			parent.observers.forEach { $0.didUpdateData(of: erasedParent) }
		}
	}
}

public extension FetchableListDataSource {
	func observingUpdates(via closure: @escaping (_ dataSource: AnyFetchableListDataSource<Element>) -> Void) -> UpdateObservingListDataSource<Self> {
		return UpdateObservingListDataSource(wrapping: self, closure: closure)
	}
}
