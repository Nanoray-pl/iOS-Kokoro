//
//  Created on 03/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

private enum NSCodingCodableError: Swift.Error {
	case castError
}

public struct NSCodingCodable<T: NSCoding>: Codable {
	public var value: T

	public init(value: T) {
		self.value = value
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let data = try container.decode(Data.self)
		let anyValue = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data).unwrap()
		guard let value = anyValue as? T else { throw NSCodingCodableError.castError }
		self.value = value
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		let data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
		try container.encode(data)
	}
}
#endif
