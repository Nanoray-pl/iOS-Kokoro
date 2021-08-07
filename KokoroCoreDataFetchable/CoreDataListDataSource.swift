//
//  Created on 06/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(CoreData) && canImport(Foundation)
import CoreData
import KokoroCoreData
import KokoroFetchable
import KokoroUtils

public enum CoreDataListDataSourceExpectedTotalCountUpdateBehavior {
	case always, firstFetch, never
}

public class CoreDataListDataSource<CoreDataType: NSManagedObject & ManagedObject, LightweightType>: FetchableListDataSource, ObjectWith {
	public typealias Page = (elements: [Element], isLast: Bool)
	public typealias Element = LightweightType

	private let stack: CoreDataStack
	private let predicate: AnyPredicateBuilder<CoreDataType>
	private let pageSize: Int
	private let expectedTotalCountUpdateBehavior: CoreDataListDataSourceExpectedTotalCountUpdateBehavior
	private let mapper: (CoreDataType) throws -> LightweightType

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	private let lock = FoundationLock()
	private var pages = [Page]()
	@Locked(via: \.lock) public private(set) var elements = [Element]()
	private var fetchingPageIndex: Int?
	private var fetchingId: UUID?
	@Locked(via: \.lock) public private(set) var expectedTotalCount: Int? = nil

	public var count: Int {
		return lock.acquireAndRun { elements.count }
	}

	@Locked(via: \.lock) public private(set) var error: Error? = nil

	public var isEmpty: Bool {
		return lock.acquireAndRun { elements.isEmpty }
	}

	public var isFetching: Bool {
		return lock.acquireAndRun { fetchingPageIndex != nil }
	}

	public var isAfterInitialFetch: Bool {
		return lock.acquireAndRun { !pages.isEmpty }
	}

	public init(
		stack: CoreDataStack,
		predicate: AnyPredicateBuilder<CoreDataType> = BoolPredicateBuilder.true.eraseToAnyPredicateBuilder(),
		pageSize: Int = 50,
		expectedTotalCountUpdateBehavior: CoreDataListDataSourceExpectedTotalCountUpdateBehavior = .always,
		mapper: @escaping (CoreDataType) throws -> LightweightType
	) {
		self.stack = stack
		self.predicate = predicate
		self.pageSize = pageSize
		self.expectedTotalCountUpdateBehavior = expectedTotalCountUpdateBehavior
		self.mapper = mapper
	}

	public subscript(index: Int) -> Element {
		return lock.acquireAndRun { elements[index] }
	}

	public func reset() {
		lock.acquireAndRun {
			fetchingId = nil
			pages = []
			error = nil
			fetchingPageIndex = nil
			expectedTotalCount = nil
			updateElements()
		}
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return lock.acquireAndRun {
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
	}

	private func fetchPage(_ index: Int) {
		lock.acquireAndRun {
			fetchingPageIndex = index
			error = nil
			let fetchingId = UUID()
			self.fetchingId = fetchingId
			updateElements()

			let request = FetchRequest<CoreDataType>(predicate: predicate, limit: pageSize, offset: index * pageSize)
			stack.backgroundContext.perform { [weak self, lock, expectedTotalCountUpdateBehavior, mapper, pageSize] context in
				lock.acquireAndRun {
					guard let self = self else { return }
					guard fetchingId == self.fetchingId else { return }
					self.fetchingId = nil
					do {
						let shouldUpdateExpectedTotalCount: Bool
						switch expectedTotalCountUpdateBehavior {
						case .always:
							shouldUpdateExpectedTotalCount = true
						case .firstFetch:
							shouldUpdateExpectedTotalCount = index == 0
						case .never:
							shouldUpdateExpectedTotalCount = false
						}
						if shouldUpdateExpectedTotalCount {
							self.expectedTotalCount = try context.count(for: request)
						}
						let elements = try context.fetch(request)
						self.pages.append((elements: try elements.map(mapper), isLast: elements.count < pageSize))
					} catch {
						self.error = error
					}
					self.updateElements()
				}
			}
		}
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		lock.acquireAndRun {
			observers.insert(.init(wrapping: observer))
		}
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		lock.acquireAndRun {
			observers.remove(withIdentity: ObjectIdentifier(observer))
		}
	}

	private func updateElements() {
		lock.acquireAndRun {
			elements = pages.flatMap(\.elements)
			let erasedSelf = eraseToAnyFetchableListDataSource()
			observers.forEach { $0.didUpdateData(of: erasedSelf) }
		}
	}
}
#endif
