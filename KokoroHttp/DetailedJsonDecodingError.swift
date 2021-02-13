//
//  Created on 20/12/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public enum DetailedJsonDecodingError: Error {
	case typeMismatch(Any.Type, DecodingError.Context, value: Any)
	case valueNotFound(Any.Type, DecodingError.Context, outerValue: Any)
	case keyNotFound(CodingKey, DecodingError.Context, outerValue: Any)
	case dataCorrupted(DecodingError.Context, value: Any)
	case undetailed(_ error: Error)
}

public class DetailedJsonDecodingErrorFactory {
	public init() {}

	private func debugValue<CodingPathCollection>(for data: Data, codingPath: CodingPathCollection, originalError: DecodingError) throws -> Any where CodingPathCollection: Collection, CodingPathCollection.Element == CodingKey {
		let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
		return try debugValue(forJsonObject: jsonObject, codingPath: codingPath, originalError: originalError)
	}

	private func debugValue<CodingPathCollection>(forJsonObject jsonObject: Any, codingPath: CodingPathCollection, originalError: DecodingError) throws -> Any where CodingPathCollection: Collection, CodingPathCollection.Element == CodingKey {
		guard let codingPathNode = codingPath.first else {
			if jsonObject is [String: Any] || jsonObject is [Any] || jsonObject is String {
				let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed)
				if let result = String(data: data, encoding: .utf8) {
					return result
				} else {
					throw originalError
				}
			} else {
				return jsonObject
			}
		}

		let nextJsonObject: Any
		if let intValue = codingPathNode.intValue {
			guard let jsonObject = jsonObject as? [Any] else { throw originalError }
			if intValue >= jsonObject.count { throw originalError }
			nextJsonObject = jsonObject[intValue]
		} else {
			guard let jsonObject = jsonObject as? [String: Any] else { throw originalError }
			if let value = jsonObject[codingPathNode.stringValue] {
				nextJsonObject = value
			} else {
				throw originalError
			}
		}

		return try debugValue(forJsonObject: nextJsonObject, codingPath: codingPath.dropFirst(), originalError: originalError)
	}

	public func detailedError(from error: DecodingError, for data: Data) -> DetailedJsonDecodingError {
		do {
			switch error {
			case let .typeMismatch(type, context):
				return .typeMismatch(type, context, value: try debugValue(for: data, codingPath: context.codingPath, originalError: error))
			case let .valueNotFound(type, context):
				return .valueNotFound(type, context, outerValue: try debugValue(for: data, codingPath: context.codingPath.dropLast(), originalError: error))
			case let .keyNotFound(key, context):
				return .keyNotFound(key, context, outerValue: try debugValue(for: data, codingPath: context.codingPath, originalError: error))
			case let .dataCorrupted(context):
				return .dataCorrupted(context, value: try debugValue(for: data, codingPath: context.codingPath, originalError: error))
			@unknown default:
				return .undetailed(error)
			}
		} catch _ {
			return .undetailed(error)
		}
	}
}
#endif
