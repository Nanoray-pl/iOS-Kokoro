//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public class UniqueListDataSource<Wrapped: FetchableListDataSource, Key: Equatable>: FetchableListDataSource {
	public typealias Element = Wrapped.Element

	private let wrapped: Wrapped
	private let uniqueKeyFunction: (Element) -> Key
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
		return nil // there is no way to know how many elements will be unique
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

	public convenience init(wrapping wrapped: Wrapped) where Element == Key {
		self.init(wrapping: wrapped, uniqueKeyFunction: { $0 })
	}

	public init(wrapping wrapped: Wrapped, uniqueKeyFunction: @escaping (Element) -> Key) {
		self.wrapped = wrapped
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
		var elements = [Element]()
		var keys = [Key]()
		wrapped.elements.forEach {
			let key = uniqueKeyFunction($0)
			if !keys.contains(key) {
				keys.append(key)
				elements.append($0)
			}
		}
		self.elements = elements

		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: UniqueListDataSource<Wrapped, Key>?

		init(parent: UniqueListDataSource<Wrapped, Key>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent?.updateData()
		}
	}
}

public extension FetchableListDataSource where Element: Equatable {
	func uniquing() -> UniqueListDataSource<Self, Element> {
		return UniqueListDataSource(wrapping: self)
	}
}

public extension FetchableListDataSource {
	func uniquing<Key>(via uniqueKeyFunction: @escaping (Element) -> Key) -> UniqueListDataSource<Self, Key> {
		return UniqueListDataSource(wrapping: self, uniqueKeyFunction: uniqueKeyFunction)
	}
}
