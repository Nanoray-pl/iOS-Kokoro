//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

/// A `FetchableListDataSource` implementation which can be built either from an array of elements or from another data source's current state.
public class SnapshotListDataSource<Element>: FetchableListDataSource {
	public let elements: [Element]
	public let error: Error?

	public var count: Int {
		return elements.count
	}

	public var isEmpty: Bool {
		return elements.isEmpty
	}

	public var isFetching: Bool {
		return false
	}

	convenience init<T>(of wrapped: T) where T: FetchableListDataSource, T.Element == Element {
		self.init(elements: wrapped.elements, error: wrapped.error)
	}

	convenience init(error: Error) {
		self.init(elements: [], error: error)
	}

	init(elements: [Element], error: Error? = nil) {
		self.elements = elements
		self.error = error
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

extension FetchableListDataSource {
	func snapshot() -> SnapshotListDataSource<Element> {
		return SnapshotListDataSource(of: self)
	}
}
