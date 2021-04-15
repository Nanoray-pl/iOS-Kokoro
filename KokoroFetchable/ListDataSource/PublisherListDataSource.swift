//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine
import KokoroUtils

/// A `FetchableListDataSource` implementation powered with data from a `Publisher`.
public class PublisherListDataSource<Element>: FetchableListDataSource {
	public typealias PageWithoutTotalCount = (elements: [Element], isLast: Bool)
	public typealias Page = (elements: [Element], isLast: Bool, totalCount: Int?)

	private let publisherSupplier: (_ pageIndex: Int) -> AnyPublisher<Page, Error>

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	private var pages = [Page]()
	public private(set) var elements = [Element]()
	private var fetchingPageIndex: Int?
	public private(set) var expectedTotalCount: Int?
	private var requestCancellable: AnyCancellable?

	public var count: Int {
		return elements.count
	}

	public private(set) var error: Error?

	public var isEmpty: Bool {
		return elements.isEmpty
	}

	public var isFetching: Bool {
		return fetchingPageIndex != nil
	}

	public var isAfterInitialFetch: Bool {
		return !pages.isEmpty
	}

	public convenience init<P>(publisherSupplier: @escaping (_ pageIndex: Int) -> P) where P: Publisher, P.Output == PageWithoutTotalCount, P.Failure == Error {
		self.init { publisherSupplier($0).map { (elements: $0.elements, isLast: $0.isLast, totalCount: nil) } }
	}

	public init<P>(publisherSupplier: @escaping (_ pageIndex: Int) -> P) where P: Publisher, P.Output == Page, P.Failure == Error {
		self.publisherSupplier = { publisherSupplier($0).eraseToAnyPublisher() }
	}

	public subscript(index: Int) -> Element {
		return elements[index]
	}

	public func reset() {
		requestCancellable?.cancel()
		pages = []
		error = nil
		fetchingPageIndex = nil
		expectedTotalCount = nil
		updateElements()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		guard fetchingPageIndex == nil else { return false }

		if let currentPage = pages.last {
			if !currentPage.isLast {
				fetchPage(pages.count)
			} else {
				return false
			}
		} else {
			fetchPage(0)
		}
		return true
	}

	private func fetchPage(_ index: Int) {
		fetchingPageIndex = index
		error = nil
		updateElements()

		requestCancellable = publisherSupplier(index)
			.sink(
				receiveCompletion: { [weak self] in
					guard let self = self else { return }
					self.fetchingPageIndex = nil
					switch $0 {
					case let .failure(error):
						self.error = error
					case .finished:
						self.error = nil
					}
					self.updateElements()
				},
				receiveValue: { [weak self] in
					self?.expectedTotalCount = $0.totalCount
					self?.pages.append($0)
				}
			)
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.remove(withIdentity: ObjectIdentifier(observer))
	}

	private func updateElements() {
		elements = pages.flatMap(\.elements)
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}
}
#endif
