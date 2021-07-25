//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public class ErrorLoggingListDataSource<Wrapped: FetchableListDataSource>: FetchableListDataSource {
	public typealias Element = Wrapped.Element

	private let wrapped: Wrapped
	private let errorMatchingStrategy: ErrorMatchingStrategy
	private let onlyUnlogged: Bool
	private let loggingClosure: (Error) -> Void
	private lazy var observer = WrappedObserver(parent: self)

	private var lastError: Error?

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	public var elements: [Element] {
		return wrapped.elements
	}

	public var count: Int {
		return wrapped.count
	}

	public var expectedTotalCount: Int? {
		return wrapped.expectedTotalCount
	}

	public var error: Error? {
		return wrapped.error.flatMap { LoggedError(wrapping: $0) }
	}

	public var isEmpty: Bool {
		return wrapped.isEmpty
	}

	public var isFetching: Bool {
		return wrapped.isFetching
	}

	public var isAfterInitialFetch: Bool {
		return wrapped.isAfterInitialFetch
	}

	public subscript(_ index: Int) -> Element {
		return wrapped[index]
	}

	public init(wrapping wrapped: Wrapped, errorMatchingStrategy: ErrorMatchingStrategy = .byDescription, onlyUnlogged: Bool = true, loggingClosure: @escaping (Error) -> Void) {
		self.wrapped = wrapped
		self.errorMatchingStrategy = errorMatchingStrategy
		self.onlyUnlogged = onlyUnlogged
		self.loggingClosure = loggingClosure
		wrapped.addObserver(observer)
	}

	deinit {
		wrapped.removeObserver(observer)
	}

	public func reset() {
		wrapped.reset()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return wrapped.fetchAdditionalData()
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.remove(withIdentity: ObjectIdentifier(observer))
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private weak var parent: ErrorLoggingListDataSource<Wrapped>?

		init(parent: ErrorLoggingListDataSource<Wrapped>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			guard let parent = parent else { return }
			if !parent.onlyUnlogged || !(dataSource.error is LoggedError) {
				let oldError = (parent.lastError as? LoggedError)?.wrappedError ?? parent.lastError
				let newError = (dataSource.error as? LoggedError)?.wrappedError ?? dataSource.error

				if !parent.errorMatchingStrategy.areMatchingErrors(newError, oldError) {
					parent.lastError = newError
					if let error = newError {
						parent.loggingClosure(error)
					}
				}
			}
			let erasedParent = parent.eraseToAnyFetchableListDataSource()
			parent.observers.forEach { $0.didUpdateData(of: erasedParent) }
		}
	}
}

public extension FetchableListDataSource {
	func loggingErrors(errorMatchingStrategy: ErrorMatchingStrategy = .byDescription, onlyUnlogged: Bool = true, via loggingClosure: @escaping (Error) -> Void) -> ErrorLoggingListDataSource<Self> {
		return ErrorLoggingListDataSource(wrapping: self, errorMatchingStrategy: errorMatchingStrategy, onlyUnlogged: onlyUnlogged, loggingClosure: loggingClosure)
	}
}
