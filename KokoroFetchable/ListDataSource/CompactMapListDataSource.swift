//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public class CompactMapListDataSource<Wrapped: FetchableListDataSource, Output>: FetchableListDataSource {
	public typealias Element = Output

	private let wrapped: Wrapped
	private let mappingFunction: (Wrapped.Element) -> Output?
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

	public init(wrapping wrapped: Wrapped, mappingFunction: @escaping (Wrapped.Element) -> Output?) {
		self.wrapped = wrapped
		self.mappingFunction = mappingFunction
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
		observers.append(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		let identifier = ObjectIdentifier(observer)
		observers.removeFirst(where: { $0.identifier == identifier })
	}

	private func updateData() {
		elements = wrapped.elements.compactMap(mappingFunction)
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers = observers.filter { $0.weakReference != nil }
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private unowned let parent: CompactMapListDataSource<Wrapped, Output>

		init(parent: CompactMapListDataSource<Wrapped, Output>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Wrapped.Element>) {
			parent.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func compactMap<Output>(_ mappingFunction: @escaping (Element) -> Output?) -> CompactMapListDataSource<Self, Output> {
		return CompactMapListDataSource(wrapping: self, mappingFunction: mappingFunction)
	}
}
