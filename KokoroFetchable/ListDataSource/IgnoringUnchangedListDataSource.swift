//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public class IgnoringUnchangedListDataSource<Element, Key: Equatable>: FetchableListDataSource {
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
		if shouldUpdateData(oldData: elements, newData: wrapped.elements) {
			elements = wrapped.elements
			let erasedSelf = eraseToAnyFetchableListDataSource()
			observers = observers.filter { $0.weakReference != nil }
			observers.forEach { $0.didUpdateData(of: erasedSelf) }
		}
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private unowned let parent: IgnoringUnchangedListDataSource<Element, Key>

		init(parent: IgnoringUnchangedListDataSource<Element, Key>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent.updateData()
		}
	}
}

public extension FetchableListDataSource where Element: Equatable {
	func ignoringUnchanged() -> IgnoringUnchangedListDataSource<Element, Element> {
		return IgnoringUnchangedListDataSource(wrapping: self)
	}
}

public extension FetchableListDataSource {
	func ignoringUnchanged<Key: Equatable>(via uniqueKeyFunction: @escaping (Element) -> Key) -> IgnoringUnchangedListDataSource<Element, Key> {
		return IgnoringUnchangedListDataSource(wrapping: self, uniqueKeyFunction: uniqueKeyFunction)
	}
}
