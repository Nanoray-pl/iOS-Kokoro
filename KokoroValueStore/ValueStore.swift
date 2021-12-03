//
//  Created on 02/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public protocol ReadOnlyValueStore: AnyObject {
	associatedtype Element

	var value: Element { get }
}

public protocol ValueStore: ReadOnlyValueStore {
	var value: Element { get set }
}

public protocol ThrowingReadOnlyValueStore: AnyObject {
	associatedtype Element

	func value() throws -> Element
}

public protocol ThrowingValueStore: ThrowingReadOnlyValueStore {
	func setValue(_ value: Element) throws
}

public class AnyReadOnlyValueStore<Element>: ReadOnlyValueStore {
	private let getter: () -> Element

	public var value: Element {
		return getter()
	}

	public init<T>(wrapping wrapped: T) where T: ReadOnlyValueStore, T.Element == Element {
		getter = { wrapped.value }
	}
}

public class AnyValueStore<Element>: ValueStore {
	private let getter: () -> Element
	private let setter: (Element) -> Void

	public var value: Element {
		get {
			return getter()
		}
		set {
			setter(newValue)
		}
	}

	public init<T>(wrapping wrapped: T) where T: ValueStore, T.Element == Element {
		getter = { wrapped.value }
		setter = { wrapped.value = $0 }
	}
}

public class AnyThrowingReadOnlyValueStore<Element>: ThrowingReadOnlyValueStore {
	private let getter: () throws -> Element

	public init<T>(wrapping wrapped: T) where T: ThrowingReadOnlyValueStore, T.Element == Element {
		getter = { try wrapped.value() }
	}

	public func value() throws -> Element {
		return try getter()
	}
}

public class AnyThrowingValueStore<Element>: ThrowingValueStore {
	private let getter: () throws -> Element
	private let setter: (Element) throws -> Void

	public init<T>(wrapping wrapped: T) where T: ThrowingValueStore, T.Element == Element {
		getter = { try wrapped.value() }
		setter = { try wrapped.setValue($0) }
	}

	public func value() throws -> Element {
		return try getter()
	}

	public func setValue(_ value: Element) throws {
		try setter(value)
	}
}

public class NonThrowingToThrowingReadOnlyValueStore<Store>: ThrowingReadOnlyValueStore where Store: ReadOnlyValueStore {
	public typealias Element = Store.Element

	private let getter: () -> Element

	public init(wrapping wrapped: Store) {
		getter = { wrapped.value }
	}

	public func value() throws -> Element {
		return getter()
	}
}

public class NonThrowingToThrowingValueStore<Store>: ThrowingValueStore where Store: ValueStore {
	public typealias Element = Store.Element

	private let getter: () -> Element
	private let setter: (Element) -> Void

	public init(wrapping wrapped: Store) {
		getter = { wrapped.value }
		setter = { wrapped.value = $0 }
	}

	public func value() throws -> Element {
		return getter()
	}

	public func setValue(_ value: Element) throws {
		setter(value)
	}
}

public extension ReadOnlyValueStore {
	func eraseToAnyReadOnlyValueStore() -> AnyReadOnlyValueStore<Element> {
		return (self as? AnyReadOnlyValueStore<Element>) ?? .init(wrapping: self)
	}

	func throwing() -> NonThrowingToThrowingReadOnlyValueStore<Self> {
		return (self as? NonThrowingToThrowingReadOnlyValueStore<Self>) ?? .init(wrapping: self)
	}
}

public extension ValueStore {
	func eraseToAnyValueStore() -> AnyValueStore<Element> {
		return (self as? AnyValueStore<Element>) ?? .init(wrapping: self)
	}

	func throwing() -> NonThrowingToThrowingValueStore<Self> {
		return (self as? NonThrowingToThrowingValueStore<Self>) ?? .init(wrapping: self)
	}
}

public extension ThrowingReadOnlyValueStore {
	func eraseToAnyThrowingReadOnlyValueStore() -> AnyThrowingReadOnlyValueStore<Element> {
		return (self as? AnyThrowingReadOnlyValueStore<Element>) ?? .init(wrapping: self)
	}
}

public extension ThrowingValueStore {
	func eraseToAnyThrowingValueStore() -> AnyThrowingValueStore<Element> {
		return (self as? AnyThrowingValueStore<Element>) ?? .init(wrapping: self)
	}
}
