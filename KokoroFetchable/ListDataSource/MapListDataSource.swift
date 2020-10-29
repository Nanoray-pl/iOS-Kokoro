//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public class MapListDataSource<Input, Output>: FetchableListDataSource {
	public typealias Element = Output

	private let wrapped: AnyFetchableListDataSource<Input>
	private let mappingFunction: (Input) -> Output
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

	public init<T>(wrapping wrapped: T, mappingFunction: @escaping (Input) -> Output) where T: FetchableListDataSource, T.Element == Input {
		self.wrapped = wrapped.eraseToAnyFetchableListDataSource()
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
		elements = wrapped.elements.map(mappingFunction)
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers = observers.filter { $0.weakReference != nil }
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		typealias Element = Input

		private unowned let parent: MapListDataSource<Input, Output>

		init(parent: MapListDataSource<Input, Output>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func map<Output>(_ mappingFunction: @escaping (Element) -> Output) -> MapListDataSource<Element, Output> {
		return MapListDataSource(wrapping: self, mappingFunction: mappingFunction)
	}
}
