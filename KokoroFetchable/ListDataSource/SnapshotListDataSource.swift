//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public enum SnapshotListDataSourceBehavior<T> {
	case snapshot
	case constant(_ value: T)

	func value(snapshot snapshotClosure: @autoclosure () -> T) -> T {
		switch self {
		case .snapshot:
			return snapshotClosure()
		case let .constant(value):
			return value
		}
	}
}

extension SnapshotListDataSourceBehavior: Equatable where T: Equatable {}
extension SnapshotListDataSourceBehavior: Hashable where T: Hashable {}

extension SnapshotListDataSourceBehavior: ExpressibleByNilLiteral where T: OptionalConvertible {
	public init(nilLiteral: ()) {
		self = .constant(T(from: nil))
	}
}

extension SnapshotListDataSourceBehavior: ExpressibleByBooleanLiteral where T: _ExpressibleByBuiltinBooleanLiteral {
	public init(booleanLiteral value: T) {
		self = .constant(value)
	}
}

extension SnapshotListDataSourceBehavior: ExpressibleByIntegerLiteral where T: _ExpressibleByBuiltinIntegerLiteral {
	public init(integerLiteral value: T) {
		self = .constant(value)
	}
}

public struct SnapshotListDataSourceConfiguration: Hashable {
	public let isFetching: SnapshotListDataSourceBehavior<Bool>
	public let isAfterInitialFetch: SnapshotListDataSourceBehavior<Bool>
	public let expectedTotalCount: SnapshotListDataSourceBehavior<Int?>

	public init(
		isFetching: SnapshotListDataSourceBehavior<Bool> = false,
		isAfterInitialFetch: SnapshotListDataSourceBehavior<Bool> = false,
		expectedTotalCount: SnapshotListDataSourceBehavior<Int?> = .snapshot
	) {
		self.isFetching = isFetching
		self.isAfterInitialFetch = isAfterInitialFetch
		self.expectedTotalCount = expectedTotalCount
	}
}

/// A `FetchableListDataSource` implementation which can be built either from an array of elements or from another data source's current state.
public class SnapshotListDataSource<Element>: FetchableListDataSource {
	public let elements: [Element]
	public let error: Error?
	public let isFetching: Bool
	public let isAfterInitialFetch: Bool
	public let expectedTotalCount: Int?

	public var count: Int {
		return elements.count
	}

	public var isEmpty: Bool {
		return elements.isEmpty
	}

	public convenience init<T>(of wrapped: T, configuration: SnapshotListDataSourceConfiguration = .init()) where T: FetchableListDataSource, T.Element == Element {
		self.init(
			elements: wrapped.elements,
			error: wrapped.error,
			isFetching: configuration.isFetching.value(snapshot: wrapped.isFetching),
			isAfterInitialFetch: configuration.isAfterInitialFetch.value(snapshot: wrapped.isAfterInitialFetch),
			expectedTotalCount: configuration.expectedTotalCount.value(snapshot: wrapped.expectedTotalCount)
		)
	}

	public convenience init(error: Error, isFetching: Bool = false, isAfterInitialFetch: Bool = false, expectedTotalCount: Int? = nil) {
		self.init(elements: [], error: error, isFetching: isFetching, expectedTotalCount: expectedTotalCount)
	}

	public init(elements: [Element], error: Error? = nil, isFetching: Bool = false, isAfterInitialFetch: Bool = false, expectedTotalCount: Int? = nil) {
		self.elements = elements
		self.error = error
		self.isFetching = isFetching
		self.isAfterInitialFetch = isAfterInitialFetch
		self.expectedTotalCount = expectedTotalCount
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
	func snapshot(configuration: SnapshotListDataSourceConfiguration = .init()) -> SnapshotListDataSource<Element> {
		return SnapshotListDataSource(of: self, configuration: configuration)
	}
}
