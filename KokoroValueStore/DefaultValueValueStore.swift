//
//  Created on 02/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public class DefaultValueValueStore<Element>: ValueStore {
	private let getter: () -> Element?
	private let setter: (Element) -> Void
	private let defaultValue: Element

	public var value: Element {
		get {
			return getter() ?? defaultValue
		}
		set {
			setter(newValue)
		}
	}

	public init<Store>(wrapping wrapped: Store, defaultValue: Element) where Store: ValueStore, Store.Element: OptionalConvertible, Store.Element.Wrapped == Element {
		self.defaultValue = defaultValue
		getter = { wrapped.value.optional() }
		setter = { wrapped.value = .init(from: $0) }
	}

	public init<Store>(wrapping wrapped: Store, defaultValue: Element) where Store: ValueStore, Store.Element: OptionalConvertible, Store.Element.Wrapped == Element, Element: Equatable {
		self.defaultValue = defaultValue
		getter = { wrapped.value.optional() }
		setter = { wrapped.value = .init(from: $0 == defaultValue ? nil : $0) }
	}
}

public class ThrowingDefaultValueValueStore<Element>: ThrowingValueStore {
	private let getter: () throws -> Element?
	private let setter: (Element) throws -> Void
	private let defaultValue: Element

	public init<Store>(wrapping wrapped: Store, defaultValue: Element) where Store: ThrowingValueStore, Store.Element: OptionalConvertible, Store.Element.Wrapped == Element {
		self.defaultValue = defaultValue
		getter = { try wrapped.value().optional() }
		setter = { try wrapped.setValue(.init(from: $0)) }
	}

	public init<Store>(wrapping wrapped: Store, defaultValue: Element) where Store: ThrowingValueStore, Store.Element: OptionalConvertible, Store.Element.Wrapped == Element, Element: Equatable {
		self.defaultValue = defaultValue
		getter = { try wrapped.value().optional() }
		setter = { try wrapped.setValue(.init(from: $0 == defaultValue ? nil : $0)) }
	}

	public func value() throws -> Element {
		return try getter() ?? defaultValue
	}

	public func setValue(_ value: Element) throws {
		try setter(value)
	}
}

public extension ValueStore where Element: OptionalConvertible {
	func withDefaultValue(_ defaultValue: Element.Wrapped) -> DefaultValueValueStore<Element.Wrapped> {
		return .init(wrapping: self, defaultValue: defaultValue)
	}
}

public extension ThrowingValueStore where Element: OptionalConvertible {
	func withDefaultValue(_ defaultValue: Element.Wrapped) -> ThrowingDefaultValueValueStore<Element.Wrapped> {
		return .init(wrapping: self, defaultValue: defaultValue)
	}
}
