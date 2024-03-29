//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public enum GroupingListDataSourceControllingGroup<Group: Comparable> {
	case none, first, last, all
	case group(_ group: Group)
	case closure(_ predicate: (Group) -> Bool)
}

/// A type which groups elements from a `FetchableListDataSource` it wraps into separate data sources.
public class GroupingListDataSource<Element, Group: Comparable>: GroupedListDataSource {
	public var dataSources: [(dataSource: AnyFetchableListDataSource<Element>, group: Group)] {
		return groupDataSources.map { (dataSource: $0.erased, group: $0.group) }
	}

	private let wrapped: AnyFetchableListDataSource<Element>
	private let controllingGroups: GroupingListDataSourceControllingGroup<Group>
	private let inherentGroup: Group?
	private let groupingClosure: (Element) -> Group
	private lazy var observer = WrappedObserver(parent: self)
	private var groupDataSources = SortedArray<GroupDataSource<Element>>(by: \.group)

	private let observers = BoxedObserverSet<WeakGroupedListDataSourceObserver<Element, Group>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	/// - Parameter wrapped: The data source to wrap.
	/// - Parameter inherentGroup: A group which should always exist in the resulting smaller data sources, even if there are no elements in it.
	/// - Parameter controllingGroups: Groups which should inherit the `error` and `isFetching` values, and whose' data source `reset()` and `fetchAdditionalData()` calls should be passed over to the wrapped data source.
	/// - Parameter groupingClosure: A closure deciding which group an element goes in.
	public init<DataSource>(wrapping wrapped: DataSource, inherentGroup: Group? = nil, controllingGroups: GroupingListDataSourceControllingGroup<Group>, groupingClosure: @escaping (Element) -> Group) where DataSource: FetchableListDataSource, DataSource.Element == Element {
		self.wrapped = wrapped.eraseToAnyFetchableListDataSource()
		self.inherentGroup = inherentGroup
		self.controllingGroups = controllingGroups
		self.groupingClosure = groupingClosure
		wrapped.addObserver(observer)
		updateData()
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

	private func updateData() {
		let elements = wrapped.elements.map { (element: $0, group: groupingClosure($0)) }

		var newGroups = [Group]()
		elements.forEach {
			if !newGroups.contains($0.group) {
				newGroups.append($0.group)
			}
		}
		if let inherentGroup = inherentGroup, !newGroups.contains(inherentGroup) {
			newGroups.append(inherentGroup)
		}

		var createdDataSources = [GroupDataSource<Element>]()
		var removedDataSources = [GroupDataSource<Element>]()
		var newGroupDataSources = groupDataSources
		newGroups.forEach { group in
			let groupDataSource: GroupDataSource<Element>
			if let existingDataSource = newGroupDataSources.first(where: { $0.group == group }) {
				groupDataSource = existingDataSource
			} else {
				let newDataSource = GroupDataSource<Element>(parent: self, group: group)
				groupDataSource = newDataSource
				newGroupDataSources.insert(newDataSource)
				createdDataSources.append(newDataSource)
			}
			groupDataSource.elements = elements.filter { $0.group == group }.map(\.element)
		}

		groupDataSources.forEach { oldGroupDataSource in
			if !newGroups.contains(oldGroupDataSource.group) {
				removedDataSources.append(oldGroupDataSource)
				newGroupDataSources.removeFirst { $0.group == oldGroupDataSource.group }
			}
		}

		groupDataSources = newGroupDataSources
		groupDataSources.forEach {
			$0.error = $0.isControllingGroup ? wrapped.error : nil
			$0.isFetching = $0.isControllingGroup && wrapped.isFetching
			$0.isAfterInitialFetch = wrapped.isAfterInitialFetch
		}

		let erasedSelf = eraseToAnyGroupedListDataSource()
		removedDataSources.forEach { groupDataSource in
			observers.forEach { $0.didRemoveGroupDataSource(groupDataSource.erased, for: groupDataSource.group, from: erasedSelf) }
		}
		createdDataSources.forEach { groupDataSource in
			observers.forEach { $0.didCreateGroupDataSource(groupDataSource.erased, for: groupDataSource.group, to: erasedSelf) }
		}
		newGroupDataSources.forEach { $0.updateObservers() }
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: GroupingListDataSource<Element, Group>?

		init(parent: GroupingListDataSource<Element, Group>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent?.updateData()
		}
	}

	private class GroupDataSource<Element>: FetchableListDataSource {
		private weak var parent: GroupingListDataSource<Element, Group>?
		private(set) lazy var erased = eraseToAnyFetchableListDataSource()

		let group: Group
		var elements = [Element]()
		var error: Error?
		var isFetching = false
		var isAfterInitialFetch = false

		var isEmpty: Bool {
			return elements.isEmpty
		}

		var count: Int {
			return elements.count
		}

		var expectedTotalCount: Int? {
			return nil // there is no way to know how many elements will be in the group
		}

		var isControllingGroup: Bool {
			guard let parent = parent else { return true }
			switch parent.controllingGroups {
			case .none:
				return false
			case .first:
				return parent.groupDataSources.first === self
			case .last:
				return parent.groupDataSources.last === self
			case .all:
				return true
			case let .group(group):
				return self.group == group
			case let .closure(predicate):
				return predicate(group)
			}
		}

		private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
			isValid: { $0.weakReference != nil },
			identity: \.identifier
		)

		subscript(index: Int) -> Element {
			return elements[index]
		}

		init(parent: GroupingListDataSource<Element, Group>, group: Group) {
			self.parent = parent
			self.group = group
		}

		func updateObservers() {
			let erased = eraseToAnyFetchableListDataSource()
			observers.forEach { $0.didUpdateData(of: erased) }
		}

		func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, Element == T.Element {
			observers.insert(.init(wrapping: observer))
		}

		func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, Element == T.Element {
			observers.remove(withIdentity: ObjectIdentifier(observer))
		}

		func reset() {
			if isControllingGroup {
				parent?.wrapped.reset()
			}
		}

		@discardableResult
		func fetchAdditionalData() -> Bool {
			if isControllingGroup {
				return parent?.wrapped.fetchAdditionalData() ?? false
			} else {
				return false
			}
		}
	}
}

public extension FetchableListDataSource {
	func grouping<Group: Comparable>(inherentGroup: Group? = nil, controllingGroups: GroupingListDataSourceControllingGroup<Group>, groupingClosure: @escaping (Element) -> Group) -> GroupingListDataSource<Element, Group> {
		return .init(wrapping: self, inherentGroup: inherentGroup, controllingGroups: controllingGroups, groupingClosure: groupingClosure)
	}
}
