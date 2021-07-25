//
//  Created on 07/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol Cache: AnyObject, Equatable {
	associatedtype Key
	associatedtype Value

	func value(for key: Key) -> Value?
	func store(_ value: Value, for key: Key)
	func invalidateValue(for key: Key)
	func invalidateAllValues()
}

public final class AnyCache<Key, Value>: Cache {
	private let getter: (Key) -> Value?
	private let setter: (Value, Key) -> Void
	private let invalidator: (Key) -> Void
	private let allValueInvalidator: () -> Void

	public init<C>(wrapping wrapped: C) where C: Cache, C.Key == Key, C.Value == Value {
		getter = { wrapped.value(for: $0) }
		setter = { wrapped.store($0, for: $1) }
		invalidator = { wrapped.invalidateValue(for: $0) }
		allValueInvalidator = { wrapped.invalidateAllValues() }
	}

	public func value(for key: Key) -> Value? {
		return getter(key)
	}

	public func store(_ value: Value, for key: Key) {
		setter(value, key)
	}

	public func invalidateValue(for key: Key) {
		invalidator(key)
	}

	public func invalidateAllValues() {
		allValueInvalidator()
	}

	public static func == (lhs: AnyCache<Key, Value>, rhs: AnyCache<Key, Value>) -> Bool {
		return lhs === rhs
	}
}

public extension Cache {
	func eraseToAnyCache() -> AnyCache<Key, Value> {
		return (self as? AnyCache<Key, Value>) ?? .init(wrapping: self)
	}
}
