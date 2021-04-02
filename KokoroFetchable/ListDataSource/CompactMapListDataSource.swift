//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public class CompactMapListDataSource<Wrapped: FetchableListDataSource, Output>: FetchableListDataSource {
	private let wrapped: Wrapped
	private let mappingFunction: (Wrapped.Element) -> Output?
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
		return nil // there is no way to know how many elements will not be nil after mapping
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

	public init(wrapping wrapped: Wrapped, mappingFunction: @escaping (Wrapped.Element) -> Output?) {
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
		elements = wrapped.elements.compactMap(mappingFunction)
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: CompactMapListDataSource<Wrapped, Output>?

		init(parent: CompactMapListDataSource<Wrapped, Output>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Wrapped.Element>) {
			parent?.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func compactMap<Output>(_ mappingFunction: @escaping (Element) -> Output?) -> CompactMapListDataSource<Self, Output> {
		return CompactMapListDataSource(wrapping: self, mappingFunction: mappingFunction)
	}
}
