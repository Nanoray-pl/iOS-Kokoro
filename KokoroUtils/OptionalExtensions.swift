//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

private enum OptionalUnwrapError: Error {
	case error
}

public protocol OptionalConvertible {
	associatedtype Wrapped

	init(from optional: Wrapped?)

	func optional() -> Wrapped?
}

extension Optional: OptionalConvertible {
	public init(from optional: Wrapped?) {
		self = optional
	}

	public func optional() -> Wrapped? {
		return self
	}

	public func unwrap() throws -> Wrapped {
		try unwrap { throw OptionalUnwrapError.error }
	}

	public func unwrap(else elseClosure: () throws -> Never) rethrows -> Wrapped {
		switch self {
		case let .some(value):
			return value
		case .none:
			try elseClosure()
		}
	}
}

public extension Result {
	func tryMap<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, Error> {
		switch self {
		case let .success(success):
			do {
				return .success(try transform(success))
			} catch {
				return .failure(error)
			}
		case let .failure(error):
			return .failure(error)
		}
	}
}
