//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public class MapGroupedListDataSource<Wrapped, Element>: GroupedListDataSource where Wrapped: GroupedListDataSource {
	private struct DataSourceEntry {
		let originalDataSource: AnyFetchableListDataSource<Wrapped.Element>
		let newDataSource: AnyFetchableListDataSource<Element>
		let group: Group
	}

	public typealias Group = Wrapped.Group

	public var dataSources: [(dataSource: AnyFetchableListDataSource<Element>, group: Group)] {
		return groupDataSources.map { (dataSource: $0.newDataSource, group: $0.group) }
	}

	private let wrapped: Wrapped
	private let mapper: (_ dataSource: AnyFetchableListDataSource<Wrapped.Element>, _ group: Group) -> AnyFetchableListDataSource<Element>

	private let observers = BoxedObserverSet<WeakGroupedListDataSourceObserver<Element, Group>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	private var groupDataSources: SortedArray<DataSourceEntry>
	private lazy var observer = WrappedObserver(parent: self)

	public init(wrapping wrapped: Wrapped, mapper: @escaping (_ dataSource: AnyFetchableListDataSource<Wrapped.Element>, _ group: Group) -> AnyFetchableListDataSource<Element>) {
		self.wrapped = wrapped
		self.mapper = mapper
		groupDataSources = SortedArray(elements: wrapped.dataSources.map { dataSource, group in .init(originalDataSource: dataSource, newDataSource: mapper(dataSource, group), group: group) }, by: \.group)
		wrapped.addObserver(observer)
	}

	deinit {
		wrapped.removeObserver(observer)
	}

	public func addObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, Element == T.Element, Group == T.Group {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, Element == T.Element, Group == T.Group {
		observers.remove(withIdentity: ObjectIdentifier(observer))
	}

	public func reset() {
		wrapped.reset()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return wrapped.fetchAdditionalData()
	}

	private class WrappedObserver: GroupedListDataSourceObserver {
		private weak var parent: MapGroupedListDataSource<Wrapped, Element>?

		init(parent: MapGroupedListDataSource<Wrapped, Element>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyGroupedListDataSource<Wrapped.Element, Group>) {
			guard let parent = parent else { return }
			let erasedParent = parent.eraseToAnyGroupedListDataSource()
			parent.observers.forEach { $0.didUpdateData(of: erasedParent) }
		}

		func didCreateGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Wrapped.Element>, for group: Group, to splitDataSource: AnyGroupedListDataSource<Wrapped.Element, Group>) {
			guard let parent = parent else { return }
			let erasedParent = parent.eraseToAnyGroupedListDataSource()
			let newDataSource = parent.mapper(groupDataSource, group)
			parent.groupDataSources.insert(.init(originalDataSource: groupDataSource, newDataSource: newDataSource, group: group))
			parent.observers.forEach { $0.didCreateGroupDataSource(newDataSource, for: group, to: erasedParent) }
		}

		func didRemoveGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Wrapped.Element>, for group: Group, from splitDataSource: AnyGroupedListDataSource<Wrapped.Element, Group>) {
			guard let parent = parent else { return }
			let erasedParent = parent.eraseToAnyGroupedListDataSource()
			guard let newDataSource = parent.groupDataSources.first(where: { $0.originalDataSource.identifier == groupDataSource.identifier })?.newDataSource else { return }
			parent.groupDataSources.removeFirst(where: { $0.originalDataSource.identifier == groupDataSource.identifier })
			parent.observers.forEach { $0.didRemoveGroupDataSource(newDataSource, for: group, from: erasedParent) }
		}
	}
}

public extension GroupedListDataSource {
	func map<Output>(_ mapper: @escaping (_ dataSource: AnyFetchableListDataSource<Element>, _ group: Group) -> AnyFetchableListDataSource<Output>) -> MapGroupedListDataSource<Self, Output> {
		return MapGroupedListDataSource(wrapping: self, mapper: mapper)
	}
}
