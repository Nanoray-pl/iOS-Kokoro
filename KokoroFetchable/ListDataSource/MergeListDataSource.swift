//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public class MergeListDataSource<Element>: FetchableListDataSource {
	private let sortStrategySupplier: ([AnyFetchableListDataSource<Element>]) -> AnyMergeListDataSourceSortStrategy<Element>
	private var sortStrategy: AnyMergeListDataSourceSortStrategy<Element>!
	private let dataSources: [AnyFetchableListDataSource<Element>]
	private lazy var observer = DataSourceObserver(parent: self)
	public private(set) var error: Error?

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: { $0.identifier }
	)

	public var elements: [Element] {
		return sortStrategy.elements
	}

	public var count: Int {
		return elements.count
	}

	public var isEmpty: Bool {
		return sortStrategy.elements.isEmpty
	}

	public var isFetching: Bool {
		return dataSources.contains(where: { $0.isFetching })
	}

	public convenience init<SortStrategy, T1, T2>(sortStrategySupplier: @escaping ([AnyFetchableListDataSource<Element>]) -> SortStrategy, dataSources dataSource1: T1, _ dataSource2: T2) where SortStrategy: MergeListDataSourceSortStrategy, T1: FetchableListDataSource, T2: FetchableListDataSource, SortStrategy.Element == Element, T1.Element == Element, T2.Element == Element {
		self.init(sortStrategySupplier: sortStrategySupplier, dataSources: [dataSource1.eraseToAnyFetchableListDataSource(), dataSource2.eraseToAnyFetchableListDataSource()])
	}

	public init<SortStrategy>(sortStrategySupplier: @escaping ([AnyFetchableListDataSource<Element>]) -> SortStrategy, dataSources: [AnyFetchableListDataSource<Element>]) where SortStrategy: MergeListDataSourceSortStrategy, SortStrategy.Element == Element {
		if dataSources.isEmpty { fatalError("Cannot create a MergeListDataSource without any child data sources") }
		self.sortStrategySupplier = { sortStrategySupplier($0).eraseToAnyMergeListDataSourceSortStrategy() }
		self.dataSources = dataSources
		setupSortStrategy()
		dataSources.forEach { $0.addObserver(observer) }
		updateData()
	}

	deinit {
		dataSources.forEach { $0.removeObserver(observer) }
	}

	public subscript(index: Int) -> Element {
		return elements[index]
	}

	private func setupSortStrategy() {
		sortStrategy = sortStrategySupplier(dataSources.map { $0.eraseToAnyFetchableListDataSource() }).eraseToAnyMergeListDataSourceSortStrategy()
	}

	public func reset() {
		sortStrategy = MergeListDataSourceNoOpSortStrategy().eraseToAnyMergeListDataSourceSortStrategy()
		dataSources.forEach { $0.reset() }
		setupSortStrategy()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		if isFetching { return false }
		var triggeredUpdate = false
		dataSources.forEach {
			let result = $0.fetchAdditionalData()
			triggeredUpdate = triggeredUpdate || result
		}
		return triggeredUpdate
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.remove(withIdentity: ObjectIdentifier(observer))
	}

	private func updateData() {
		sortStrategy.updateElements()
		updateError()

		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private func updateError() {
		let errors = dataSources.compactMap(\.error)
		switch errors.count {
		case 1:
			error = errors[0]
		case 0:
			error = nil
		default:
			error = FetchableListDataSourceError.multipleErrors(errors)
		}
	}

	private class DataSourceObserver: FetchableListDataSourceObserver {
		private weak var parent: MergeListDataSource<Element>?

		init(parent: MergeListDataSource<Element>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent?.updateData()
		}
	}
}

public protocol MergeListDataSourceSortStrategy {
	associatedtype Element

	var elements: [Element] { get }

	func updateElements()
}

public final class AnyMergeListDataSourceSortStrategy<Element>: MergeListDataSourceSortStrategy {
	private let elementsClosure: () -> [Element]
	private let updateElementsClosure: () -> Void

	public var elements: [Element] {
		return elementsClosure()
	}

	public init<T>(wrapping wrapped: T) where T: MergeListDataSourceSortStrategy, T.Element == Element {
		elementsClosure = { wrapped.elements }
		updateElementsClosure = { wrapped.updateElements() }
	}

	public func updateElements() {
		updateElementsClosure()
	}
}

public extension MergeListDataSourceSortStrategy {
	func eraseToAnyMergeListDataSourceSortStrategy() -> AnyMergeListDataSourceSortStrategy<Element> {
		return (self as? AnyMergeListDataSourceSortStrategy<Element>) ?? .init(wrapping: self)
	}
}

private class MergeListDataSourceNoOpSortStrategy<Element>: MergeListDataSourceSortStrategy {
	let elements = [Element]()

	func updateElements() {}
}

public class MergeListDataSourceByDataSourceSortStrategy<Element>: MergeListDataSourceSortStrategy {
	private let dataSources: [AnyFetchableListDataSource<Element>]
	public private(set) var elements = [Element]()

	public init(dataSources: [AnyFetchableListDataSource<Element>]) {
		self.dataSources = dataSources
	}

	public func updateElements() {
		elements = dataSources.flatMap(\.elements)
	}
}

public class MergeListDataSourceByPageSortStrategy<Element, Key: Equatable>: MergeListDataSourceSortStrategy {
	private let dataSources: [AnyFetchableListDataSource<Element>]
	private let uniqueKeyFunction: (Element) -> Key
	private var dataSourceKeyCache: [[Key]]
	public private(set) var elements = [Element]()

	public init(dataSources: [AnyFetchableListDataSource<Element>], uniqueKeyFunction: @escaping (Element) -> Key) {
		self.dataSources = dataSources
		self.uniqueKeyFunction = uniqueKeyFunction
		dataSourceKeyCache = Array(repeating: [], count: dataSources.count)
	}

	public func updateElements() {
		var elements = self.elements
		for dataSourceIndex in 0 ..< dataSources.count {
			let dataSource = dataSources[dataSourceIndex]
			if dataSource.count < dataSourceKeyCache[dataSourceIndex].count {
				fatalError("Inconsistent element cache: elements were removed")
			}
			for elementIndex in 0 ..< dataSourceKeyCache[dataSourceIndex].count {
				let cachedKey = dataSourceKeyCache[dataSourceIndex][elementIndex]
				let currentKey = uniqueKeyFunction(dataSource[elementIndex])
				if currentKey != cachedKey {
					fatalError("Inconsistent element cache: elements were changed")
				}
			}
			let addedElements = dataSource.elements.dropFirst(dataSourceKeyCache[dataSourceIndex].count)
			elements.append(contentsOf: addedElements)
			dataSourceKeyCache[dataSourceIndex].append(contentsOf: addedElements.map { uniqueKeyFunction($0) })
		}
		self.elements = elements
	}
}

public extension MergeListDataSourceByPageSortStrategy where Element == Key {
	convenience init(dataSources: [AnyFetchableListDataSource<Element>]) {
		self.init(dataSources: dataSources, uniqueKeyFunction: { $0 })
	}
}
