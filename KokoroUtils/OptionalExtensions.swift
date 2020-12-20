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

	func unwrap() throws -> Wrapped {
		switch self {
		case let .some(value):
			return value
		case .none:
			throw OptionalUnwrapError.error
		}
	}
}

public extension Optional where Wrapped: StringProtocol {
	var isEmpty: Bool {
		return self?.isEmpty != false
	}
}

public extension Result where Failure == Error {
	func tryMap<NewSuccess>(_ transform: (Success) throws -> NewSuccess) -> Result<NewSuccess, Failure> {
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
