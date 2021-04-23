//
//  Created on 08/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

@propertyWrapper
public struct AnyProxy<EnclosingSelf, Value> {
	public typealias Getter = (_ self: EnclosingSelf) -> Value
	public typealias Setter = (_ self: EnclosingSelf, _ newValue: Value) -> Void
	public typealias DidSetWithoutOldValueClosure = (_ self: EnclosingSelf, _ newValue: Value) -> Void
	public typealias DidSetWithOldValueClosure = (_ self: EnclosingSelf, _ oldValue: Value, _ newValue: Value) -> Void

	private let getter: Getter
	private let setter: Setter
	private let didSetWithoutOldValueClosure: DidSetWithoutOldValueClosure?
	private let didSetWithOldValueClosure: DidSetWithOldValueClosure?

	@available(*, unavailable, message: "@(Any)Proxy can only be applied to classes")
	public var wrappedValue: Value {
		get { fatalError("@(Any)Proxy can only be applied to classes") }
		set { fatalError("@(Any)Proxy can only be applied to classes") } // swiftlint:disable:this unused_setter_value
	}

	public static subscript(_enclosingInstance observed: EnclosingSelf, wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>) -> Value {
		get {
			let storageValue = observed[keyPath: storageKeyPath]
			return storageValue.getter(observed)
		}
		set {
			let storageValue = observed[keyPath: storageKeyPath]
			if let didSetWithOldValueClosure = storageValue.didSetWithOldValueClosure {
				let value = storageValue.getter(observed)
				storageValue.setter(observed, newValue)
				didSetWithOldValueClosure(observed, value, newValue)
			} else {
				storageValue.setter(observed, newValue)
				storageValue.didSetWithoutOldValueClosure?(observed, newValue)
			}
		}
	}

	public init(getter: @escaping Getter, setter: @escaping Setter, didSet didSetClosure: DidSetWithoutOldValueClosure? = nil) {
		self.getter = getter
		self.setter = setter
		self.didSetWithoutOldValueClosure = didSetClosure
		didSetWithOldValueClosure = nil
	}

	public init(getter: @escaping Getter, setter: @escaping Setter, didSet didSetClosure: DidSetWithOldValueClosure?) {
		self.getter = getter
		self.setter = setter
		self.didSetWithOldValueClosure = didSetClosure
		didSetWithoutOldValueClosure = nil
	}

	public init(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, didSet didSetClosure: DidSetWithoutOldValueClosure? = nil) {
		self.init(
			getter: { $0[keyPath: keyPath] },
			setter: { $0[keyPath: keyPath] = $1 },
			didSet: didSetClosure
		)
	}

	public init(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, didSet didSetClosure: DidSetWithOldValueClosure?) {
		self.init(
			getter: { $0[keyPath: keyPath] },
			setter: { $0[keyPath: keyPath] = $1 },
			didSet: didSetClosure
		)
	}

	public init<KeyPathValue>(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, KeyPathValue>, getMapper: @escaping (KeyPathValue) -> Value, setMapper: @escaping (Value) -> KeyPathValue, didSet didSetClosure: DidSetWithoutOldValueClosure? = nil) {
		self.init(
			getter: { getMapper($0[keyPath: keyPath]) },
			setter: { $0[keyPath: keyPath] = setMapper($1) },
			didSet: didSetClosure
		)
	}

	public init<KeyPathValue>(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, KeyPathValue>, getMapper: @escaping (KeyPathValue) -> Value, setMapper: @escaping (Value) -> KeyPathValue, didSet didSetClosure: DidSetWithOldValueClosure?) {
		self.init(
			getter: { getMapper($0[keyPath: keyPath]) },
			setter: { $0[keyPath: keyPath] = setMapper($1) },
			didSet: didSetClosure
		)
	}

	public init(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, multiplier: Value, didSet didSetClosure: DidSetWithoutOldValueClosure? = nil) where Value: BinaryInteger {
		self.init(
			keyPath,
			getMapper: { $0 * multiplier },
			setMapper: { $0 / multiplier },
			didSet: didSetClosure
		)
	}

	public init(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, multiplier: Value, didSet didSetClosure: DidSetWithOldValueClosure?) where Value: BinaryInteger {
		self.init(
			keyPath,
			getMapper: { $0 * multiplier },
			setMapper: { $0 / multiplier },
			didSet: didSetClosure
		)
	}

	public init(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, multiplier: Value, didSet didSetClosure: DidSetWithoutOldValueClosure? = nil) where Value: FloatingPoint {
		self.init(
			keyPath,
			getMapper: { $0 * multiplier },
			setMapper: { $0 / multiplier },
			didSet: didSetClosure
		)
	}

	public init(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, multiplier: Value, didSet didSetClosure: DidSetWithOldValueClosure?) where Value: FloatingPoint {
		self.init(
			keyPath,
			getMapper: { $0 * multiplier },
			setMapper: { $0 / multiplier },
			didSet: didSetClosure
		)
	}
}
