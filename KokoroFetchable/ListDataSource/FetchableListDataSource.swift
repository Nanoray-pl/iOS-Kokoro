//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public enum FetchableListDataSourceError: Error {
	case multipleErrors(_ errors: [Error])
}

public protocol FetchableListDataSourceObserver: AnyObject {
	associatedtype Element

	func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>)
}

public final class WeakFetchableListDataSourceObserver<Element>: FetchableListDataSourceObserver {
	public let identifier: ObjectIdentifier
	public private(set) weak var weakReference: AnyObject?
	private let didUpdateDataClosure: (_ dataSource: AnyFetchableListDataSource<Element>) -> Void

	public init<T>(wrapping wrapped: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		identifier = ObjectIdentifier(wrapped)
		weakReference = wrapped
		didUpdateDataClosure = { [weak wrapped] in wrapped?.didUpdateData(of: $0) }
	}

	public func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
		didUpdateDataClosure(dataSource)
	}
}

public protocol FetchableListDataSource: AnyObject, RandomAccessCollection where Index == Int {
	associatedtype Element

	var identifier: ObjectIdentifier { get }
	var elements: [Element] { get }
	var expectedTotalCount: Int? { get }
	var error: Error? { get }
	var isFetching: Bool { get }
	var isAfterInitialFetch: Bool { get }

	func reset()

	@discardableResult
	func fetchAdditionalData() -> Bool

	func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element
	func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element
}

public extension FetchableListDataSource {
	var identifier: ObjectIdentifier {
		return ObjectIdentifier(self)
	}

	var fetchable: Fetchable<[Element], Error> {
		if isFetching {
			return .fetching
		} else if let error = error {
			return .failure(error)
		} else {
			return .success(elements)
		}
	}

	var fetchState: DataSourceFetchState<Error> {
		if isFetching {
			return .fetching
		} else if let error = error {
			return .failure(error)
		} else {
			return .success
		}
	}

	func eraseToAnyFetchableListDataSource() -> AnyFetchableListDataSource<Element> {
		return (self as? AnyFetchableListDataSource<Element>) ?? .init(wrapping: self)
	}

	var startIndex: Int {
		return 0
	}

	var endIndex: Int {
		return count
	}
}

private class AnyFetchableListDataSourceBase<Element>: FetchableListDataSource {
	var elements: [Element] {
		fatalError("Not overriden abstract member")
	}

	var count: Int {
		fatalError("Not overriden abstract member")
	}

	var expectedTotalCount: Int? {
		fatalError("Not overriden abstract member")
	}

	var error: Error? {
		fatalError("Not overriden abstract member")
	}

	var isEmpty: Bool {
		fatalError("Not overriden abstract member")
	}

	var isFetching: Bool {
		fatalError("Not overriden abstract member")
	}

	var isAfterInitialFetch: Bool {
		fatalError("Not overriden abstract member")
	}

	subscript(_ index: Int) -> Element {
		fatalError("Not overriden abstract member")
	}

	func reset() {
		fatalError("Not overriden abstract member")
	}

	@discardableResult
	func fetchAdditionalData() -> Bool {
		fatalError("Not overriden abstract member")
	}

	func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		fatalError("Not overriden abstract member")
	}

	func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		fatalError("Not overriden abstract member")
	}
}

private class AnyFetchableListDataSourceBox<Wrapped>: AnyFetchableListDataSourceBase<Wrapped.Element> where Wrapped: FetchableListDataSource {
	typealias Element = Wrapped.Element

	private let wrapped: Wrapped

	override var elements: [Element] {
		return wrapped.elements
	}

	override var count: Int {
		return wrapped.count
	}

	override var expectedTotalCount: Int? {
		return wrapped.expectedTotalCount
	}

	override var error: Error? {
		return wrapped.error
	}

	override var isEmpty: Bool {
		return wrapped.isEmpty
	}

	override var isFetching: Bool {
		return wrapped.isFetching
	}

	override var isAfterInitialFetch: Bool {
		return wrapped.isAfterInitialFetch
	}

	override subscript(index: Int) -> Element {
		return wrapped[index]
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

	override func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		wrapped.addObserver(observer)
	}

	override func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		wrapped.removeObserver(observer)
	}
}

public final class AnyFetchableListDataSource<Element>: FetchableListDataSource {
	private let box: AnyFetchableListDataSourceBase<Element>

	public var elements: [Element] {
		return box.elements
	}

	public var count: Int {
		return box.count
	}

	public var expectedTotalCount: Int? {
		return box.expectedTotalCount
	}

	public var error: Error? {
		return box.error
	}

	public var isEmpty: Bool {
		return box.isEmpty
	}

	public var isFetching: Bool {
		return box.isFetching
	}

	public var isAfterInitialFetch: Bool {
		return box.isAfterInitialFetch
	}

	public subscript(index: Int) -> Element {
		return box[index]
	}

	public init<T>(wrapping wrapped: T) where T: FetchableListDataSource, T.Element == Element {
		box = AnyFetchableListDataSourceBox(wrapping: wrapped)
	}

	public func reset() {
		box.reset()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return box.fetchAdditionalData()
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		box.addObserver(observer)
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		box.removeObserver(observer)
	}
}
