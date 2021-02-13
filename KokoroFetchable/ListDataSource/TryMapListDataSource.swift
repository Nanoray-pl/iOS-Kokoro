//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public enum TryMapListDataSourceErrorBehavior {
	case skipElement, emptyList
}

public class TryMapListDataSource<Wrapped: FetchableListDataSource, Output>: FetchableListDataSource {
	public typealias Element = Output

	private let wrapped: Wrapped
	private let errorBehavior: TryMapListDataSourceErrorBehavior
	private let mappingFunction: (Wrapped.Element) throws -> Output
	private lazy var observer = WrappedObserver(parent: self)
	private var observers = [WeakFetchableListDataSourceObserver<Element>]()
	public private(set) var elements = [Element]()
	public private(set) var error: Error?

	public var count: Int {
		return elements.count
	}

	public var isEmpty: Bool {
		return elements.isEmpty
	}

	public var isFetching: Bool {
		return wrapped.isFetching
	}

	public init(wrapping wrapped: Wrapped, errorBehavior: TryMapListDataSourceErrorBehavior = .skipElement, mappingFunction: @escaping (Wrapped.Element) throws -> Output) {
		self.wrapped = wrapped
		self.errorBehavior = errorBehavior
		self.mappingFunction = mappingFunction
		wrapped.addObserver(observer)
		updateData()
	}

	deinit {
		wrapped.removeObserver(observer)
	}

	public subscript(index: Int) -> Element {
		return elements[index]
	}

	public func reset() {
		wrapped.reset()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return wrapped.fetchAdditionalData()
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.append(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		let identifier = ObjectIdentifier(observer)
		observers.removeFirst(where: { $0.identifier == identifier })
	}

	private func updateData() {
		var elements = [Element]()
		var errors = [Error]()
		if let error = wrapped.error {
			errors.append(error)
		}

		switch errorBehavior {
		case .skipElement:
			wrapped.elements.forEach {
				do {
					elements.append(try mappingFunction($0))
				} catch {
					errors.append(error)
				}
			}
		case .emptyList:
			do {
				elements = try wrapped.elements.map(mappingFunction)
			} catch {
				errors.append(error)
			}
		}

		switch errors.count {
		case 1:
			error = errors[0]
		case 0:
			error = nil
		default:
			error = FetchableListDataSourceError.multipleErrors(errors)
		}

		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers = observers.filter { $0.weakReference != nil }
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class WrappedObserver: FetchableListDataSourceObserver {
		private unowned let parent: TryMapListDataSource<Wrapped, Output>

		init(parent: TryMapListDataSource<Wrapped, Output>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Wrapped.Element>) {
			parent.updateData()
		}
	}
}

public extension FetchableListDataSource {
	func tryMap<Output>(errorBehavior: TryMapListDataSourceErrorBehavior = .skipElement, _ mappingFunction: @escaping (Element) throws -> Output) -> TryMapListDataSource<Self, Output> {
		return TryMapListDataSource(wrapping: self, errorBehavior: errorBehavior, mappingFunction: mappingFunction)
	}
}
