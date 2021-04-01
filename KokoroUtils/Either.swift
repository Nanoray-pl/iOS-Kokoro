//
//  Created on 01/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public struct EitherDecodingError: Error {
	public let first: Error
	public let second: Error

	public init(first: Error, second: Error) {
		self.first = first
		self.second = second
	}
}

public enum Either<A, B> {
	case first(_ value: A)
	case second(_ value: B)
}

extension Either: Equatable where A: Equatable, B: Equatable {}
extension Either: Hashable where A: Hashable, B: Hashable {}

extension Either: Decodable where A: Decodable, B: Decodable {
	public init(from decoder: Decoder) throws {
		do {
			self = .first(try A(from: decoder))
		} catch let firstError {
			do {
				self = .second(try B(from: decoder))
			} catch let secondError {
				throw EitherDecodingError(first: firstError, second: secondError)
			}
		}
	}
}

extension Either: Encodable where A: Encodable, B: Encodable {
	public func encode(to encoder: Encoder) throws {
		switch self {
		case let .first(value):
			try value.encode(to: encoder)
		case let .second(value):
			try value.encode(to: encoder)
		}
	}
}
