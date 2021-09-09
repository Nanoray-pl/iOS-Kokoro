//
//  Created on 09/09/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public class EnumeratedListDataSource<Wrapped: FetchableListDataSource>: FetchableListDataSource {
	public typealias Element = (offset: Int, element: Wrapped.Element)

	private let wrapped: Wrapped
	private lazy var observer = WrappedObserver(parent: self)
	public private(set) var elements = [Element]()

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	public var count: Int {
		return elements.count
	}

	public var expectedTotalCount: Int? {
		return wrapped.expectedTotalCount
	}

	public var error: Error? {
		return wrapped.error
	}

	public var isEmpty: Bool {
		return elements.isEmpty
	}

	public var isFetching: Bool {
		return wrapped.isFetching
	}

	public var isAfterInitialFetch: Bool {
		return wrapped.isAfterInitialFetch
	}

	public init(wrapping wrapped: Wrapped) {
		self.wrapped = wrapped
		wrapped.addObserver(observer)
		updateData()
	}

	deinit {
		wrapped.removeObserver(observer)
	}

	public subscript(index: Int) -> Element {
		return elements[index]
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

	private func updateData() {
		elements = Array(wrapped.elements.enumerated())
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: EnumeratedListDataSource<Wrapped>?

		init(parent: EnumeratedListDataSource<Wrapped>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Wrapped.Element>) {
			parent?.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func enumeratedDataSource() -> EnumeratedListDataSource<Self> {
		return EnumeratedListDataSource(wrapping: self)
	}
}
