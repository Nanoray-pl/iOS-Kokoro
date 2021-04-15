//
//  Created on 08/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

@propertyWrapper
public struct AnyProxy<EnclosingSelf, Value> {
	private let keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>

	@available(*, unavailable, message: "@(Any)Proxy can only be applied to classes")
	public var wrappedValue: Value {
		get { fatalError("@(Any)Proxy can only be applied to classes") }
		set { fatalError("@(Any)Proxy can only be applied to classes") } // swiftlint:disable:this unused_setter_value
	}

	public static subscript(_enclosingInstance observed: EnclosingSelf, wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>, storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>) -> Value {
		get {
			let storageValue = observed[keyPath: storageKeyPath]
			let value = observed[keyPath: storageValue.keyPath]
			return value
		}
		set {
			let storageValue = observed[keyPath: storageKeyPath]
			observed[keyPath: storageValue.keyPath] = newValue
		}
	}

	public init(_ keyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>) {
		self.keyPath = keyPath
	}
}
