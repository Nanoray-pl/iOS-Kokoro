//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public protocol GroupedListDataSourceObserver: AnyObject {
	associatedtype Element
	associatedtype Group: Comparable

	func didUpdateData(of dataSource: AnyGroupedListDataSource<Element, Group>)
	func didCreateGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Element>, for group: Group, to splitDataSource: AnyGroupedListDataSource<Element, Group>)
	func didRemoveGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Element>, for group: Group, from splitDataSource: AnyGroupedListDataSource<Element, Group>)
}

public class WeakGroupedListDataSourceObserver<Element, Group: Comparable>: GroupedListDataSourceObserver {
	public let identifier: ObjectIdentifier
	public private(set) weak var weakReference: AnyObject?
	private let didUpdateDataClosure: (_ dataSource: AnyGroupedListDataSource<Element, Group>) -> Void
	private let didCreateGroupDataSourceClosure: (_ groupDataSource: AnyFetchableListDataSource<Element>, _ group: Group, _ splitDataSource: AnyGroupedListDataSource<Element, Group>) -> Void
	private let didRemoveGroupDataSourceClosure: (_ groupDataSource: AnyFetchableListDataSource<Element>, _ group: Group, _ splitDataSource: AnyGroupedListDataSource<Element, Group>) -> Void

	public init<T>(wrapping wrapped: T) where T: GroupedListDataSourceObserver, T.Element == Element, T.Group == Group {
		identifier = ObjectIdentifier(wrapped)
		weakReference = wrapped
		didUpdateDataClosure = { [weak wrapped] in wrapped?.didUpdateData(of: $0) }
		didCreateGroupDataSourceClosure = { [weak wrapped] in wrapped?.didCreateGroupDataSource($0, for: $1, to: $2) }
		didRemoveGroupDataSourceClosure = { [weak wrapped] in wrapped?.didRemoveGroupDataSource($0, for: $1, from: $2) }
	}

	public func didUpdateData(of dataSource: AnyGroupedListDataSource<Element, Group>) {
		didUpdateDataClosure(dataSource)
	}

	public func didCreateGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Element>, for group: Group, to splitDataSource: AnyGroupedListDataSource<Element, Group>) {
		didCreateGroupDataSourceClosure(groupDataSource, group, splitDataSource)
	}

	public func didRemoveGroupDataSource(_ groupDataSource: AnyFetchableListDataSource<Element>, for group: Group, from splitDataSource: AnyGroupedListDataSource<Element, Group>) {
		didRemoveGroupDataSourceClosure(groupDataSource, group, splitDataSource)
	}
}

public protocol GroupedListDataSource: AnyObject {
	associatedtype Element
	associatedtype Group: Comparable

	var identifier: ObjectIdentifier { get }
	var dataSources: [(dataSource: AnyFetchableListDataSource<Element>, group: Group)] { get }

	func reset()

	@discardableResult
	func fetchAdditionalData() -> Bool

	func addObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, Element == T.Element, Group == T.Group
	func removeObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, Element == T.Element, Group == T.Group
}

public extension GroupedListDataSource {
	var identifier: ObjectIdentifier {
		return ObjectIdentifier(self)
	}

	func eraseToAnyGroupedListDataSource() -> AnyGroupedListDataSource<Element, Group> {
		return (self as? AnyGroupedListDataSource<Element, Group>) ?? .init(wrapping: self)
	}
}

private class AnyGroupedListDataSourceBase<Element, Group: Comparable>: GroupedListDataSource {
	var dataSources: [(dataSource: AnyFetchableListDataSource<Element>, group: Group)] {
		fatalError("Not overriden abstract member")
	}

	func reset() {
		fatalError("Not overriden abstract member")
	}

	@discardableResult
	func fetchAdditionalData() -> Bool {
		fatalError("Not overriden abstract member")
	}

	func addObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, T.Element == Element, T.Group == Group {
		fatalError("Not overriden abstract member")
	}

	func removeObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, T.Element == Element, T.Group == Group {
		fatalError("Not overriden abstract member")
	}
}

private class AnyGroupedListDataSourceBox<Wrapped>: AnyGroupedListDataSourceBase<Wrapped.Element, Wrapped.Group> where Wrapped: GroupedListDataSource {
	typealias Element = Wrapped.Element

	private let wrapped: Wrapped

	override var dataSources: [(dataSource: AnyFetchableListDataSource<Element>, group: Group)] {
		return wrapped.dataSources
	}

	init(wrapping wrapped: Wrapped) {
		self.wrapped = wrapped
	}

	override func reset() {
		wrapped.reset()
	}

	@discardableResult
	override func fetchAdditionalData() -> Bool {
		return wrapped.fetchAdditionalData()
	}

	override func addObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, T.Element == Element, T.Group == Group {
		wrapped.addObserver(observer)
	}

	override func removeObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, T.Element == Element, T.Group == Group {
		wrapped.removeObserver(observer)
	}
}

public final class AnyGroupedListDataSource<Element, Group: Comparable>: GroupedListDataSource {
	private let box: AnyGroupedListDataSourceBase<Element, Group>

	public var dataSources: [(dataSource: AnyFetchableListDataSource<Element>, group: Group)] {
		return box.dataSources
	}

	public init<T>(wrapping wrapped: T) where T: GroupedListDataSource, T.Element == Element, T.Group == Group {
		box = AnyGroupedListDataSourceBox(wrapping: wrapped)
	}

	public func reset() {
		box.reset()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return box.fetchAdditionalData()
	}

	public func addObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, T.Element == Element, T.Group == Group {
		box.addObserver(observer)
	}

	public func removeObserver<T>(_ observer: T) where T: GroupedListDataSourceObserver, T.Element == Element, T.Group == Group {
		box.removeObserver(observer)
	}
}
