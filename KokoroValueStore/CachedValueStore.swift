//
//  Created on 02/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public class CachedValueStore<Store>: ValueStore where Store: ValueStore {
	public typealias Element = Store.Element

	private enum State {
		case notCached
		case cached(_ value: Element)
	}

	private let wrapped: Store
	private var state = State.notCached

	public var value: Element {
		get {
			switch state {
			case .notCached:
				let value = wrapped.value
				state = .cached(value)
				return value
			case let .cached(value):
				return value
			}
		}
		set {
			wrapped.value = newValue
			state = .cached(newValue)
		}
	}

	public init(wrapping wrapped: Store) {
		self.wrapped = wrapped
	}
}

public class ThrowingCachedValueStore<Store>: ThrowingValueStore where Store: ThrowingValueStore {
	public typealias Element = Store.Element

	private enum State {
		case notCached
		case cached(_ value: Element)
	}

	private let wrapped: Store
	private var state = State.notCached

	public init(wrapping wrapped: Store) {
		self.wrapped = wrapped
	}

	public func value() throws -> Element {
		switch state {
		case .notCached:
			let value = try wrapped.value()
			state = .cached(value)
			return value
		case let .cached(value):
			return value
		}
	}

	public func setValue(_ value: Element) throws {
		try wrapped.setValue(value)
		state = .cached(value)
	}
}

public extension ValueStore {
	func caching() -> CachedValueStore<Self> {
		return .init(wrapping: self)
	}
}

public extension ThrowingValueStore {
	func caching() -> ThrowingCachedValueStore<Self> {
		return .init(wrapping: self)
	}
}
