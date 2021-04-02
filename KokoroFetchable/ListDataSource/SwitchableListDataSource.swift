//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

/// A `FetchableListDataSource` implementation which allows switching the actual data source, keeping the previous data source's data until the new one finishes fetching.
public class SwitchableListDataSource<Element>: FetchableListDataSource {
	private var currentDataSource: AnyFetchableListDataSource<Element>
	private var targetDataSource: AnyFetchableListDataSource<Element>?
	private lazy var currentDataSourceObserver = DataSourceObserver(parent: self)
	private lazy var targetDataSourceObserver = DataSourceObserver(parent: self)

	private let observers = BoxedObserverSet<WeakFetchableListDataSourceObserver<Element>, ObjectIdentifier>(
		isValid: { $0.weakReference != nil },
		identity: \.identifier
	)

	public var elements: [Element] {
		return currentDataSource.elements
	}

	public var count: Int {
		return currentDataSource.count
	}

	public var expectedTotalCount: Int? {
		return currentDataSource.expectedTotalCount
	}

	public var error: Error? {
		return currentDataSource.error
	}

	public var isEmpty: Bool {
		return currentDataSource.isEmpty
	}

	public var isFetching: Bool {
		return targetDataSource?.isFetching ?? currentDataSource.isFetching
	}

	public var isAfterInitialFetch: Bool {
		return targetDataSource?.isAfterInitialFetch ?? currentDataSource.isAfterInitialFetch
	}

	public subscript(index: Int) -> Element {
		return currentDataSource[index]
	}

	public init<DataSource>(initialDataSource: DataSource) where DataSource: FetchableListDataSource, DataSource.Element == Element {
		currentDataSource = initialDataSource.eraseToAnyFetchableListDataSource()
		currentDataSource.addObserver(currentDataSourceObserver)
	}

	public func reset() {
		currentDataSource = targetDataSource ?? currentDataSource
		targetDataSource = nil
		currentDataSource.reset()
	}

	@discardableResult
	public func fetchAdditionalData() -> Bool {
		return (targetDataSource ?? currentDataSource).fetchAdditionalData()
	}

	public func addObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.insert(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		observers.remove(withIdentity: ObjectIdentifier(observer))
	}

	/// Switches the data source to `targetDataSource`.
	/// - Parameter targetDataSource: The data source to switch to.
	/// - Parameter replacingCurrent: Whether the internal data source should be completely replaced, as if it was the initial data source, without waiting for it to finish fetching. Defaults to `false`.
	public func switchDataSource<DataSource>(to targetDataSource: DataSource, replacingCurrent: Bool = false) where DataSource: FetchableListDataSource, DataSource.Element == Element {
		if replacingCurrent || (!targetDataSource.isFetching && (!targetDataSource.isEmpty || targetDataSource.error != nil)) {
			self.targetDataSource?.removeObserver(targetDataSourceObserver)
			self.targetDataSource = nil
			currentDataSource.removeObserver(currentDataSourceObserver)
			currentDataSource = targetDataSource.eraseToAnyFetchableListDataSource()
			currentDataSource.addObserver(currentDataSourceObserver)
			updateObservers()
			return
		}
		if let existingTargetDataSource = self.targetDataSource {
			existingTargetDataSource.removeObserver(targetDataSourceObserver)
		}
		self.targetDataSource = targetDataSource.eraseToAnyFetchableListDataSource()
		targetDataSource.addObserver(targetDataSourceObserver)
	}

	private func didUpdateData(of observer: DataSourceObserver, dataSource: AnyFetchableListDataSource<Element>) {
		if observer === currentDataSourceObserver {
			updateObservers()
		} else if observer === targetDataSourceObserver {
			if !dataSource.isFetching {
				dataSource.removeObserver(targetDataSourceObserver)
				currentDataSource.removeObserver(currentDataSourceObserver)
				currentDataSource = dataSource
				currentDataSource.addObserver(currentDataSourceObserver)
				targetDataSource = nil
				updateObservers()
			}
		} else {
			fatalError("Unknown observer \(observer)")
		}
	}

	private func updateObservers() {
		let erasedSelf = eraseToAnyFetchableListDataSource()
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class DataSourceObserver: FetchableListDataSourceObserver {
		private weak var parent: SwitchableListDataSource<Element>?

		init(parent: SwitchableListDataSource<Element>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent?.didUpdateData(of: self, dataSource: dataSource)
		}
	}
}
