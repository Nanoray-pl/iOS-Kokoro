//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine

public class PublisherListDataSource<Element, Scheduler: Combine.Scheduler>: FetchableListDataSource {
	public typealias Page = (elements: [Element], isLast: Bool)

	private let scheduler: Scheduler?
	private let publisherSupplier: (_ pageIndex: Int) -> AnyPublisher<Page, Error>
	private var observers = [WeakFetchableListDataSourceObserver<Element>]()

	private var pages = [Page]()
	public private(set) var elements = [Element]()
	private var fetchingPageIndex: Int?
	private var requestCancellable: AnyCancellable?

	public var count: Int {
		return elements.count
	}

	public private(set) var error: Error?

	public var isFetching: Bool {
		return fetchingPageIndex != nil
	}

	public init<P>(scheduler: Scheduler? = nil, publisherSupplier: @escaping (_ pageIndex: Int) -> P) where P: Publisher, P.Output == Page, P.Failure == Error {
		self.scheduler = scheduler
		self.publisherSupplier = { publisherSupplier($0).eraseToAnyPublisher() }
	}

	public subscript(index: Int) -> Element {
		return elements[index]
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		guard fetchingPageIndex == nil else { return false }

		if let currentPage = pages.last {
			if !currentPage.isLast {
				fetchPage(pages.count + 1)
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

		var publisher = publisherSupplier(index).eraseToAnyPublisher()
		if let scheduler = scheduler {
			publisher = publisher
				.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
				.receive(on: scheduler)
				.eraseToAnyPublisher()
		}

		requestCancellable = publisher
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
					self?.pages.append($0)
				}
			)
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.append(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		let identifier = ObjectIdentifier(observer)
		if let index = observers.firstIndex(where: { $0.identifier == identifier }) {
			observers.remove(at: index)
		}
	}

	private func updateElements() {
		elements = pages.flatMap { $0.elements }
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers = observers.filter { $0.weakReference != nil }
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}
}
#endif
