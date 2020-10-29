//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public struct Identifier<T, KeyType: Decodable>: Decodable {
	public let wrappedValue: KeyType

	public init(_ wrappedValue: KeyType) {
		self.wrappedValue = wrappedValue
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		self.wrappedValue = try container.decode(KeyType.self)
	}
}

extension Identifier: Encodable where KeyType: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(wrappedValue)
	}
}

extension Identifier: CustomStringConvertible where KeyType: CustomStringConvertible {
	public var description: String {
		return wrappedValue.description
	}
}

extension Identifier: Equatable where KeyType: Equatable {}
extension Identifier: Hashable where KeyType: Hashable {}

extension Identifier: Comparable where KeyType: Comparable {
	public static func < (lhs: Identifier<T, KeyType>, rhs: Identifier<T, KeyType>) -> Bool {
		return lhs.wrappedValue < rhs.wrappedValue
	}
}
