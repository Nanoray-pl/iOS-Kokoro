//
//  Created on 01/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public struct Either3DecodingError: Error {
	public let first: Error
	public let second: Error
	public let third: Error

	public init(first: Error, second: Error, third: Error) {
		self.first = first
		self.second = second
		self.third = third
	}
}

public enum Either3<A, B, C> {
	case first(_ value: A)
	case second(_ value: B)
	case third(_ value: C)
}

extension Either3: Equatable where A: Equatable, B: Equatable, C: Equatable {}
extension Either3: Hashable where A: Hashable, B: Hashable, C: Hashable {}

extension Either3: CaseIterable where A: CaseIterable, B: CaseIterable, C: CaseIterable {
	public static var allCases: [Either3<A, B, C>] {
		return A.allCases.map { .first($0) } + B.allCases.map { .second($0) } + C.allCases.map { .third($0) }
	}
}

extension Either3: Decodable where A: Decodable, B: Decodable, C: Decodable {
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
					throw Either3DecodingError(first: firstError, second: secondError, third: thirdError)
				}
			}
		}
	}
}

extension Either3: Encodable where A: Encodable, B: Encodable, C: Encodable {
	public func encode(to encoder: Encoder) throws {
		switch self {
		case let .first(value):
			try value.encode(to: encoder)
		case let .second(value):
			try value.encode(to: encoder)
		case let .third(value):
			try value.encode(to: encoder)
		}
	}
}
