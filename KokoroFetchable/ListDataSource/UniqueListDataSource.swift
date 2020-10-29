//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public class UniqueListDataSource<Element, Key: Equatable>: FetchableListDataSource {
	private let wrapped: AnyFetchableListDataSource<Element>
	private let uniqueKeyFunction: (Element) -> Key
	private lazy var observer = WrappedObserver(parent: self)
	private var observers = [WeakFetchableListDataSourceObserver<Element>]()
	public private(set) var elements = [Element]()

	public var count: Int {
		return elements.count
	}

	public var error: Error? {
		return wrapped.error
	}

	public var isFetching: Bool {
		return wrapped.isFetching
	}

	public convenience init<T>(wrapping wrapped: T) where T: FetchableListDataSource, T.Element == Element, Element == Key {
		self.init(wrapping: wrapped, uniqueKeyFunction: { $0 })
	}

	public init<T>(wrapping wrapped: T, uniqueKeyFunction: @escaping (Element) -> Key) where T: FetchableListDataSource, T.Element == Element {
		self.wrapped = wrapped.eraseToAnyFetchableListDataSource()
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

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return wrapped.fetchAdditionalData()
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
		observers = observers.filter { $0.weakReference != nil }
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private unowned let parent: UniqueListDataSource<Element, Key>

		init(parent: UniqueListDataSource<Element, Key>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent.updateData()
		}
	}
}

public extension FetchableListDataSource where Element: Equatable {
	func uniquing() -> UniqueListDataSource<Element, Element> {
		return UniqueListDataSource(wrapping: self)
	}
}

public extension FetchableListDataSource {
	func uniquing<Key>(via uniqueKeyFunction: @escaping (Element) -> Key) -> UniqueListDataSource<Element, Key> {
		return UniqueListDataSource(wrapping: self, uniqueKeyFunction: uniqueKeyFunction)
	}
}
