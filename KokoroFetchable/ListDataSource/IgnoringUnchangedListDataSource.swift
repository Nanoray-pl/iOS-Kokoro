//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public class IgnoringUnchangedListDataSource<Wrapped: FetchableListDataSource, Key: Equatable>: FetchableListDataSource {
	public typealias Element = Wrapped.Element

	private let wrapped: Wrapped
	private let errorMatchingStrategy: ErrorMatchingStrategy
	private let uniqueKeyFunction: (Element) -> Key
	private lazy var observer = WrappedObserver(parent: self)
	public private(set) var elements = [Element]()
	public private(set) var error: Error?
	public private(set) var isFetching = false
	public private(set) var isAfterInitialFetch = false
	public private(set) var expectedTotalCount: Int?

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	public var count: Int {
		return elements.count
	}

	public var isEmpty: Bool {
		return elements.isEmpty
	}

	public convenience init(wrapping wrapped: Wrapped, errorMatchingStrategy: ErrorMatchingStrategy = .byDescription) where Element == Key {
		self.init(wrapping: wrapped, uniqueKeyFunction: { $0 })
	}

	public init(wrapping wrapped: Wrapped, errorMatchingStrategy: ErrorMatchingStrategy = .byDescription, uniqueKeyFunction: @escaping (Element) -> Key) {
		self.wrapped = wrapped
		self.errorMatchingStrategy = errorMatchingStrategy
		self.uniqueKeyFunction = uniqueKeyFunction
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
		elements = []
		error = nil
		isFetching = false
		isAfterInitialFetch = false
		expectedTotalCount = nil
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

	private func shouldUpdateData(oldData: [Element], newData: [Element]) -> Bool {
		if oldData.count != newData.count {
			return true
		}
		for index in 0 ..< oldData.count {
			if uniqueKeyFunction(oldData[index]) != uniqueKeyFunction(newData[index]) {
				return true
			}
		}
		return false
	}

	private func updateData() {
		if isFetching != wrapped.isFetching || isAfterInitialFetch != wrapped.isAfterInitialFetch || expectedTotalCount != wrapped.expectedTotalCount || !errorMatchingStrategy.areMatchingErrors(error, wrapped.error) || shouldUpdateData(oldData: elements, newData: wrapped.elements) {
			elements = wrapped.elements
			error = wrapped.error
			isFetching = wrapped.isFetching
			isAfterInitialFetch = wrapped.isAfterInitialFetch
			expectedTotalCount = wrapped.expectedTotalCount
			let erasedSelf = eraseToAnyFetchableListDataSource()
			observers.forEach { $0.didUpdateData(of: erasedSelf) }
		}
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: IgnoringUnchangedListDataSource<Wrapped, Key>?

		init(parent: IgnoringUnchangedListDataSource<Wrapped, Key>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent?.updateData()
		}
	}
}

public extension FetchableListDataSource where Element: Equatable {
	func ignoringUnchanged(errorMatchingStrategy: ErrorMatchingStrategy = .byDescription) -> IgnoringUnchangedListDataSource<Self, Element> {
		return IgnoringUnchangedListDataSource(wrapping: self, errorMatchingStrategy: errorMatchingStrategy)
	}
}

public extension FetchableListDataSource {
	func ignoringUnchanged<Key: Equatable>(errorMatchingStrategy: ErrorMatchingStrategy = .byDescription, via uniqueKeyFunction: @escaping (Element) -> Key) -> IgnoringUnchangedListDataSource<Self, Key> {
		return IgnoringUnchangedListDataSource(wrapping: self, errorMatchingStrategy: errorMatchingStrategy, uniqueKeyFunction: uniqueKeyFunction)
	}
}
