//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUtils

public class SwitchableListDataSource<Element>: FetchableListDataSource {
	private var currentDataSource: AnyFetchableListDataSource<Element>
	private var targetDataSource: AnyFetchableListDataSource<Element>?
	private var observers = [WeakFetchableListDataSourceObserver<Element>]()
	private lazy var currentDataSourceObserver = DataSourceObserver(parent: self)
	private lazy var targetDataSourceObserver = DataSourceObserver(parent: self)

	public var elements: [Element] {
		return currentDataSource.elements
	}

	public var count: Int {
		return currentDataSource.count
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
		observers.append(.init(wrapping: observer))
	}

	public func removeObserver<T>(_ observer: T) where T: FetchableListDataSourceObserver, T.Element == Element {
		let identifier = ObjectIdentifier(observer)
		observers.removeFirst(where: { $0.identifier == identifier })
	}

	public func switchDataSource<DataSource>(to targetDataSource: DataSource) where DataSource: FetchableListDataSource, DataSource.Element == Element {
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
		observers = observers.filter { $0.weakReference != nil }
		observers.forEach { $0.didUpdateData(of: erasedSelf) }
	}

	private class DataSourceObserver: FetchableListDataSourceObserver {
		private unowned let parent: SwitchableListDataSource<Element>

		init(parent: SwitchableListDataSource<Element>) {
			self.parent = parent
		}

		func didUpdateData(of dataSource: AnyFetchableListDataSource<Element>) {
			parent.didUpdateData(of: self, dataSource: dataSource)
		}
	}
}
