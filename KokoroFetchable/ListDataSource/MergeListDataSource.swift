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
		identity: \.identifier
	)

	public var elements: [Element] {
		return sortStrategy.elements
	}

	public var count: Int {
		return elements.count
	}

	public var expectedTotalCount: Int? {
		return dataSources.compactMap(\.expectedTotalCount).takeIf { $0.count == dataSources.count }?.reduce(0, +)
	}

	public var isEmpty: Bool {
		return sortStrategy.isEmpty
	}

	public var isFetching: Bool {
		return dataSources.contains { $0.isFetching }
	}

	public var isAfterInitialFetch: Bool {
		return dataSources.contains { $0.isAfterInitialFetch }
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
	var isEmpty: Bool { get }

	func updateElements()
}

public final class AnyMergeListDataSourceSortStrategy<Element>: MergeListDataSourceSortStrategy {
	private let elementsClosure: () -> [Element]
	private let isEmptyClosure: () -> Bool
	private let updateElementsClosure: () -> Void

	public var elements: [Element] {
		return elementsClosure()
	}

	public var isEmpty: Bool {
		return isEmptyClosure()
	}

	public init<T>(wrapping wrapped: T) where T: MergeListDataSourceSortStrategy, T.Element == Element {
		elementsClosure = { wrapped.elements }
		isEmptyClosure = { wrapped.isEmpty }
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

	var isEmpty: Bool {
		return true
	}

	func updateElements() {}
}

/// A `MergeListDataSourceSortStrategy` implementation which outputs elements from its data sources in such a way, that all of the elements from the first data source will be first, then from the second, etc.
/// - Note: This sort strategy is unstable - an element which was previously found at a specific index may after an update end up at a different index.
public class MergeListDataSourceByDataSourceSortStrategy<Element>: MergeListDataSourceSortStrategy {
	private let dataSources: [AnyFetchableListDataSource<Element>]
	public private(set) var elements = [Element]()

	public var isEmpty: Bool {
		return elements.isEmpty
	}

	public init(dataSources: [AnyFetchableListDataSource<Element>]) {
		self.dataSources = dataSources
	}

	public func updateElements() {
		elements = dataSources.flatMap(\.elements)
	}
}

/// A `MergeListDataSourceSortStrategy` implementation which outputs elements from its data sources in the insertion order. For example, if there are two data sources, one with elements `["1", "2", "3"]`, and the other with elements `["A", "B", "C"]` and then both data sources update to `["1", "2", "3", "4", "5"]` and `["A", "B", "C", "D", "E"]` accordingly, then the output list will be `["1", "2", "3", "A", "B", "C", "4", "5", "D", "E"]`.
/// - Note: This sort strategy is stable - an element which was previously found at a specific index will always be at the same index after an update.
/// - Warning: This sort strategy requires its input data sources to provide elements in an incremental way. No elements may be removed, moved or changed from either of the input data sources. Doing so will cause a `fatalError` to be thrown.
public class MergeListDataSourceByPageSortStrategy<Element, Key: Equatable>: MergeListDataSourceSortStrategy {
	private let dataSources: [AnyFetchableListDataSource<Element>]
	private let uniqueKeyFunction: (Element) -> Key
	private var dataSourceKeyCache: [[Key]]
	public private(set) var elements = [Element]()

	public var isEmpty: Bool {
		return elements.isEmpty
	}

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
