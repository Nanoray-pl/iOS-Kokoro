//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public class FilterListDataSource<Wrapped: FetchableListDataSource>: FetchableListDataSource {
	public typealias Element = Wrapped.Element

	private let wrapped: Wrapped
	private let predicateFunction: (Element) -> Bool
	private lazy var observer = WrappedObserver(parent: self)
	public private(set) var elements = [Element]()

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	public var count: Int {
		return elements.count
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

	public init(wrapping wrapped: Wrapped, predicateFunction: @escaping (Element) -> Bool) {
		self.wrapped = wrapped
		self.predicateFunction = predicateFunction
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
		elements = wrapped.elements.filter(predicateFunction)
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: FilterListDataSource<Wrapped>?

		init(parent: FilterListDataSource<Wrapped>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent?.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func filter(_ predicateFunction: @escaping (Element) -> Bool) -> FilterListDataSource<Self> {
		return FilterListDataSource(wrapping: self, predicateFunction: predicateFunction)
	}
}
