//
//  Created on 01/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public protocol GroupingListDataSourceObserver: class {
	associatedtype Element
	associatedtype Group: Comparable

	func didUpdateData(of dataSource: GroupingListDataSource<Element, Group>)
	func didCreateGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Element>, to splitDataSource: GroupingListDataSource<Element, Group>)
	func didRemoveGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Element>, from splitDataSource: GroupingListDataSource<Element, Group>)
}

public final class WeakSplitListDataSourceObserver<Element, Group: Comparable>: GroupingListDataSourceObserver {
	public let identifier: ObjectIdentifier
	public private(set) weak var weakReference: AnyObject?
	private let didUpdateDataClosure: (_ dataSource: GroupingListDataSource<Element, Group>) -> Void
	private let didCreateGroupDataSourceClosure: (_ groupDataSource: AnyFetchableListDataSource<Element>, _ splitDataSource: GroupingListDataSource<Element, Group>) -> Void
	private let didRemoveGroupDataSourceClosure: (_ groupDataSource: AnyFetchableListDataSource<Element>, _ splitDataSource: GroupingListDataSource<Element, Group>) -> Void

	public init<T>(wrapping wrapped: T) where T: GroupingListDataSourceObserver, T.Element == Element, T.Group == Group {
		identifier = ObjectIdentifier(wrapped)
		weakReference = wrapped
		didUpdateDataClosure = { [weak wrapped] in wrapped?.didUpdateData(of: $0) }
		didCreateGroupDataSourceClosure = { [weak wrapped] in wrapped?.didCreateGroupDataSource($0, to: $1) }
		didRemoveGroupDataSourceClosure = { [weak wrapped] in wrapped?.didRemoveGroupDataSource($0, from: $1) }
	}

	public func didUpdateData(of dataSource: GroupingListDataSource<Element, Group>) {
		didUpdateDataClosure(dataSource)
	}

	public func didCreateGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Element>, to splitDataSource: GroupingListDataSource<Element, Group>) {
		didCreateGroupDataSourceClosure(groupDataSource, splitDataSource)
	}

	public func didRemoveGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Element>, from splitDataSource: GroupingListDataSource<Element, Group>) {
		didRemoveGroupDataSourceClosure(groupDataSource, splitDataSource)
	}
}

public enum SplitListDataSourceControllingGroup<Group: Comparable> {
	case none, first, last, all
	case group(_ group: Group)
	case closure(_ predicate: (Group) -> Bool)
}

/// A type which groups elements from a `FetchableListDataSource` it wraps into separate data sources.
public class GroupingListDataSource<Element, Group: Comparable> {
	public var dataSources: [(dataSource: AnyFetchableListDataSource<Element>, group: Group)] {
		return groupDataSources.map { (dataSource: $0.erased, group: $0.group) }
	}

	public var count: Int {
		return wrapped.count
	}

	public var error: Error? {
		return wrapped.error
	}

	public var isFetching: Bool {
		return wrapped.isFetching
	}

	private let wrapped: AnyFetchableListDataSource<Element>
	private let controllingGroups: SplitListDataSourceControllingGroup<Group>
	private let inherentGroup: Group?
	private let groupingClosure: (Element) -> Group
	private lazy var observer = WrappedObserver(parent: self)
	private var groupDataSources = SortedArray<GroupDataSource<Element>>(by: \.group)

	private let observers = BoxedObserverSet<WeakSplitListDataSourceObserver<Element, Group>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	/// - Parameter wrapped: The data source to wrap.
	/// - Parameter inherentGroup: A group which should always exist in the resulting smaller data sources, even if there are no elements in it.
	/// - Parameter controllingGroups: Groups which should inherit the `error` and `isFetching` values, and whose' data source `reset()` and `fetchAdditionalData()` calls should be passed over to the wrapped data source.
	/// - Parameter groupingClosure: A closure deciding which group an element goes in.
	public init<DataSource>(wrapping wrapped: DataSource, inherentGroup: Group? = nil, controllingGroups: SplitListDataSourceControllingGroup<Group>, groupingClosure: @escaping (Element) -> Group) where DataSource: FetchableListDataSource, DataSource.Element == Element {
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

	public func addObserver<T>(_ observer: T) where T: GroupingListDataSourceObserver, Element == T.Element, Group == T.Group {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: GroupingListDataSourceObserver, Element == T.Element, Group == T.Group {
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
		}

		removedDataSources.forEach { groupDataSource in
			observers.forEach { $0.didRemoveGroupDataSource(groupDataSource.erased, from: self) }
		}
		createdDataSources.forEach { groupDataSource in
			observers.forEach { $0.didCreateGroupDataSource(groupDataSource.erased, to: self) }
		}
		newGroupDataSources.forEach { $0.updateObservers() }
		observers.forEach { $0.didUpdateData(of: self) }
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

		var isEmpty: Bool {
			return elements.isEmpty
		}

		var count: Int {
			return elements.count
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
