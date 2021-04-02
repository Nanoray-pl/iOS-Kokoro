//
//  Created on 02/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public class MapValueStore<Store, Element>: ValueStore where Store: ValueStore {
	private let wrapped: Store
	private let readMapper: (Store.Element) -> Element
	private let writeMapper: (Element) -> Store.Element

	public var value: Element {
		get {
			return readMapper(wrapped.value)
		}
		set {
			wrapped.value = writeMapper(newValue)
		}
	}

	public init(wrapping wrapped: Store, readMapper: @escaping (Store.Element) -> Element, writeMapper: @escaping (Element) -> Store.Element) {
		self.wrapped = wrapped
		self.readMapper = readMapper
		self.writeMapper = writeMapper
	}
}

public class ThrowingMapValueStore<Store, Element>: ThrowingValueStore where Store: ThrowingValueStore {
	private let wrapped: Store
	private let readMapper: (Store.Element) -> Element
	private let writeMapper: (Element) -> Store.Element

	public init(wrapping wrapped: Store, readMapper: @escaping (Store.Element) -> Element, writeMapper: @escaping (Element) -> Store.Element) {
		self.wrapped = wrapped
		self.readMapper = readMapper
		self.writeMapper = writeMapper
	}

	public func value() throws -> Element {
		return readMapper(try wrapped.value())
	}

	public func setValue(_ value: Element) throws {
		try wrapped.setValue(writeMapper(value))
	}
}

public extension ValueStore {
	func map<NewElement>(readMapper: @escaping (Element) -> NewElement, writeMapper: @escaping (NewElement) -> Element) -> MapValueStore<Self, NewElement> {
		return .init(wrapping: self, readMapper: readMapper, writeMapper: writeMapper)
	}
}

public extension ThrowingValueStore {
	func map<NewElement>(readMapper: @escaping (Element) -> NewElement, writeMapper: @escaping (NewElement) -> Element) -> ThrowingMapValueStore<Self, NewElement> {
		return .init(wrapping: self, readMapper: readMapper, writeMapper: writeMapper)
	}
}
