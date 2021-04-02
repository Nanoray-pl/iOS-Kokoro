//
//  Created on 02/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUtils

public class ErrorHandlingValueStore<Store>: ValueStore where Store: ThrowingValueStore {
	public typealias Element = Store.Element

	private let wrapped: Store
	private let defaultValue: Element
	private let getterErrorHandler: (_ error: Error) -> Void
	private let setterErrorHandler: (_ newValue: Element, _ error: Error) -> Void

	public var value: Element {
		get {
			do {
				return try wrapped.value()
			} catch {
				getterErrorHandler(error)
				return defaultValue
			}
		}
		set {
			do {
				try wrapped.setValue(newValue)
			} catch {
				setterErrorHandler(newValue, error)
			}
		}
	}

	public init(
		wrapping wrapped: Store,
		defaultValue: Element,
		getterErrorHandler: @escaping (_ error: Error) -> Void,
		setterErrorHandler: @escaping (_ newValue: Element, _ error: Error) -> Void
	) {
		self.wrapped = wrapped
		self.defaultValue = defaultValue
		self.getterErrorHandler = getterErrorHandler
		self.setterErrorHandler = setterErrorHandler
	}

	convenience init(
		wrapping wrapped: Store,
		defaultValue: Element,
		errorHandler: @escaping (_ error: Error) -> Void
	) {
		self.init(
			wrapping: wrapped,
			defaultValue: defaultValue,
			getterErrorHandler: errorHandler,
			setterErrorHandler: { _, error in errorHandler(error) }
		)
	}
}

public extension ThrowingValueStore {
	func handlingErrors(
		defaultValue: Element,
		getterErrorHandler: @escaping (_ error: Error) -> Void,
		setterErrorHandler: @escaping (_ newValue: Element, _ error: Error) -> Void
	) -> ErrorHandlingValueStore<Self> {
		return .init(wrapping: self, defaultValue: defaultValue, getterErrorHandler: getterErrorHandler, setterErrorHandler: setterErrorHandler)
	}

	func handlingErrors(
		defaultValue: Element,
		errorHandler: @escaping (_ error: Error) -> Void
	) -> ErrorHandlingValueStore<Self> {
		return .init(wrapping: self, defaultValue: defaultValue, errorHandler: errorHandler)
	}
}

public extension ThrowingValueStore where Element: OptionalConvertible {
	func handlingErrors(
		getterErrorHandler: @escaping (_ error: Error) -> Void,
		setterErrorHandler: @escaping (_ newValue: Element, _ error: Error) -> Void
	) -> ErrorHandlingValueStore<Self> {
		return .init(wrapping: self, defaultValue: .init(from: nil), getterErrorHandler: getterErrorHandler, setterErrorHandler: setterErrorHandler)
	}

	func handlingErrors(
		errorHandler: @escaping (_ error: Error) -> Void
	) -> ErrorHandlingValueStore<Self> {
		return .init(wrapping: self, defaultValue: .init(from: nil), errorHandler: errorHandler)
	}
}
