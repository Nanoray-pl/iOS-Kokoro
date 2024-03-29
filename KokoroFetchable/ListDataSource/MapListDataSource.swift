//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public class MapListDataSource<Wrapped: FetchableListDataSource, Output>: FetchableListDataSource {
	private let wrapped: Wrapped
	private let mappingFunction: (Wrapped.Element) -> Output
	private lazy var observer = WrappedObserver(parent: self)
	public private(set) var elements = [Output]()

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Output>, ObjectIdentifier>(
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

	public init(wrapping wrapped: Wrapped, mappingFunction: @escaping (Wrapped.Element) -> Output) {
		self.wrapped = wrapped
		self.mappingFunction = mappingFunction
		wrapped.addObserver(observer)
		updateData()
	}

	deinit {
		wrapped.removeObserver(observer)
	}

	public subscript(index: Int) -> Output {
		return elements[index]
	}

	public func reset() {
		wrapped.reset()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return wrapped.fetchAdditionalData()
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Output {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Output {
		observers.remove(withIdentity: ObjectIdentifier(observer))
	}

	private func updateData() {
		elements = wrapped.elements.map(mappingFunction)
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: MapListDataSource<Wrapped, Output>?

		init(parent: MapListDataSource<Wrapped, Output>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Wrapped.Element>) {
			parent?.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func map<Output>(_ mappingFunction: @escaping (Element) -> Output) -> MapListDataSource<Self, Output> {
		return MapListDataSource(wrapping: self, mappingFunction: mappingFunction)
	}
}
