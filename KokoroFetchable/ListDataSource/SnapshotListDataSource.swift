//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public enum SnapshotListDataSourceIsFetchingBehavior: ExpressibleByBooleanLiteral {
	case `false`, `true`, snapshot

	public init(booleanLiteral value: BooleanLiteralType) {
		self = (value ? .true : .false)
	}
}

/// A `FetchableListDataSource` implementation which can be built either from an array of elements or from another data source's current state.
public class SnapshotListDataSource<Element>: FetchableListDataSource {
	public let elements: [Element]
	public let error: Error?
	public let isFetching: Bool

	public var count: Int {
		return elements.count
	}

	public var isEmpty: Bool {
		return elements.isEmpty
	}

	public convenience init<T>(of wrapped: T, isFetching: SnapshotListDataSourceIsFetchingBehavior = .false) where T: FetchableListDataSource, T.Element == Element {
		let isFetchingBool: Bool
		switch isFetching {
		case .false:
			isFetchingBool = false
		case .true:
			isFetchingBool = true
		case .snapshot:
			isFetchingBool = wrapped.isFetching
		}
		self.init(elements: wrapped.elements, error: wrapped.error, isFetching: isFetchingBool)
	}

	public convenience init(error: Error, isFetching: Bool = false) {
		self.init(elements: [], error: error, isFetching: isFetching)
	}

	public init(elements: [Element], error: Error? = nil, isFetching: Bool = false) {
		self.elements = elements
		self.error = error
		self.isFetching = isFetching
	}

	public subscript(index: Int) -> Element {
		return elements[index]
	}

	public func reset() {
		// do nothing
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return false
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		// do nothing, this data source will not change, no point storing observers
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		// do nothing, this data source will not change, no point storing observers
	}
}

public extension FetchableListDataSource {
	func snapshot(isFetching: SnapshotListDataSourceIsFetchingBehavior = .false) -> SnapshotListDataSource<Element> {
		return SnapshotListDataSource(of: self, isFetching: isFetching)
	}
}
