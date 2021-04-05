//
//  Created on 02/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import Foundation
import KokoroUtils

public class UserDefaultsValueStore<Element>: ValueStore {
	private let userDefaults: UserDefaults
	private let key: String
	private let getter: (_ userDefaults: UserDefaults, _ key: String) -> Element
	private let setter: (_ userDefaults: UserDefaults, _ key: String, _ value: Element) -> Void

	public var value: Element {
		get {
			return getter(userDefaults, key)
		}
		set {
			setter(userDefaults, key, newValue)
		}
	}

	public init(
		userDefaults: UserDefaults = .standard,
		key: String,
		getter: @escaping (_ userDefaults: UserDefaults, _ key: String) -> Element,
		setter: @escaping (_ userDefaults: UserDefaults, _ key: String, _ value: Element) -> Void
	) {
		self.userDefaults = userDefaults
		self.key = key
		self.getter = getter
		self.setter = setter
	}

	fileprivate static func setRawValue(_ value: Element?, forKey key: String, in userDefaults: UserDefaults) {
		if let value = value {
			userDefaults.setValue(value, forKey: key)
		} else {
			userDefaults.removeObject(forKey: key)
		}
	}
}

public class ThrowingUserDefaultsValueStore<Element>: ThrowingValueStore {
	private let userDefaults: UserDefaults
	private let key: String
	private let getter: (_ userDefaults: UserDefaults, _ key: String) throws -> Element
	private let setter: (_ userDefaults: UserDefaults, _ key: String, _ value: Element) throws -> Void

	public init(
		userDefaults: UserDefaults = .standard,
		key: String,
		getter: @escaping (_ userDefaults: UserDefaults, _ key: String) throws -> Element,
		setter: @escaping (_ userDefaults: UserDefaults, _ key: String, _ value: Element) throws -> Void
	) {
		self.userDefaults = userDefaults
		self.key = key
		self.getter = getter
		self.setter = setter
	}

	public func value() throws -> Element {
		return try getter(userDefaults, key)
	}

	public func setValue(_ value: Element) throws {
		try setter(userDefaults, key, value)
	}
}

public extension UserDefaultsValueStore where Element == Bool? {
	convenience init(userDefaults: UserDefaults = .standard, key: String) {
		self.init(
			userDefaults: userDefaults,
			key: key,
			getter: { userDefaults, key in userDefaults.object(forKey: key).flatMap { _ in userDefaults.bool(forKey: key) } },
			setter: { userDefaults, key, value in Self.setRawValue(value, forKey: key, in: userDefaults) }
		)
	}
}

public extension UserDefaultsValueStore where Element == Int? {
	convenience init(userDefaults: UserDefaults = .standard, key: String) {
		self.init(
			userDefaults: userDefaults,
			key: key,
			getter: { userDefaults, key in userDefaults.object(forKey: key).flatMap { _ in userDefaults.integer(forKey: key) } },
			setter: { userDefaults, key, value in Self.setRawValue(value, forKey: key, in: userDefaults) }
		)
	}
}

public extension UserDefaultsValueStore where Element == Float? {
	convenience init(userDefaults: UserDefaults = .standard, key: String) {
		self.init(
			userDefaults: userDefaults,
			key: key,
			getter: { userDefaults, key in userDefaults.object(forKey: key).flatMap { _ in userDefaults.float(forKey: key) } },
			setter: { userDefaults, key, value in Self.setRawValue(value, forKey: key, in: userDefaults) }
		)
	}
}

public extension UserDefaultsValueStore where Element == Double? {
	convenience init(userDefaults: UserDefaults = .standard, key: String) {
		self.init(
			userDefaults: userDefaults,
			key: key,
			getter: { userDefaults, key in userDefaults.object(forKey: key).flatMap { _ in userDefaults.double(forKey: key) } },
			setter: { userDefaults, key, value in Self.setRawValue(value, forKey: key, in: userDefaults) }
		)
	}
}

public extension UserDefaultsValueStore where Element == String? {
	convenience init(userDefaults: UserDefaults = .standard, key: String) {
		self.init(
			userDefaults: userDefaults,
			key: key,
			getter: { userDefaults, key in userDefaults.object(forKey: key).flatMap { _ in userDefaults.string(forKey: key) } },
			setter: { userDefaults, key, value in UserDefaultsValueStore.setRawValue(value, forKey: key, in: userDefaults) }
		)
	}
}

public extension ThrowingUserDefaultsValueStore where Element: OptionalConvertible, Element.Wrapped: Codable {
	convenience init(userDefaults: UserDefaults = .standard, key: String, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
		self.init(
			userDefaults: userDefaults,
			key: key,
			getter: { userDefaults, key in
				guard let data = userDefaults.data(forKey: key) else { return .init(from: nil) }
				return .init(from: try decoder.decode(Element.Wrapped.self, from: data))
			},
			setter: { userDefaults, key, value in
				guard let value = value.optional() else {
					userDefaults.removeObject(forKey: key)
					return
				}
				userDefaults.set(try encoder.encode(value), forKey: key)
			}
		)
	}
}
