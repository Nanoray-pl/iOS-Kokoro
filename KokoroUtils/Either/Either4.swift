//
//  Created on 01/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public struct Either4DecodingError: Error {
	public let first: Error
	public let second: Error
	public let third: Error
	public let fourth: Error

	public init(first: Error, second: Error, third: Error, fourth: Error) {
		self.first = first
		self.second = second
		self.third = third
		self.fourth = fourth
	}
}

public enum Either4<A, B, C, D> {
	case first(_ value: A)
	case second(_ value: B)
	case third(_ value: C)
	case fourth(_ value: D)
}

extension Either4: Equatable where A: Equatable, B: Equatable, C: Equatable, D: Equatable {}
extension Either4: Hashable where A: Hashable, B: Hashable, C: Hashable, D: Hashable {}

extension Either4: Decodable where A: Decodable, B: Decodable, C: Decodable, D: Decodable {
	public init(from decoder: Decoder) throws {
		do {
			self = .first(try A(from: decoder))
		} catch let firstError {
			do {
				self = .second(try B(from: decoder))
			} catch let secondError {
				do {
					self = .third(try C(from: decoder))
				} catch let thirdError {
					do {
						self = .fourth(try D(from: decoder))
					} catch let fourthError {
						throw Either4DecodingError(first: firstError, second: secondError, third: thirdError, fourth: fourthError)
					}
				}
			}
		}
	}
}

extension Either4: Encodable where A: Encodable, B: Encodable, C: Encodable, D: Encodable {
	public func encode(to encoder: Encoder) throws {
		switch self {
		case let .first(value):
			try value.encode(to: encoder)
		case let .second(value):
			try value.encode(to: encoder)
		case let .third(value):
			try value.encode(to: encoder)
		case let .fourth(value):
			try value.encode(to: encoder)
		}
	}
}
