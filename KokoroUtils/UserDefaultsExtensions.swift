//
//  Created on 05/11/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import Foundation

private let userDefaultsCodableValueDateFormatter = Foundation.DateFormatter().with {
	$0.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
	$0.calendar = Calendar(identifier: .iso8601)
	$0.timeZone = TimeZone(secondsFromGMT: 0)
	$0.locale = Locale(identifier: "en_US_POSIX")
}

public extension UserDefaults {
	indirect enum CodableValue: Codable {
		private enum ObjectCodingKeys: String, CodingKey {
			case type, value
		}

		private enum ObjectType: String, Codable {
			case null, url, utf8Data, binaryData, date
		}

		case null
		case bool(_ value: Bool)
		case float(_ value: Float)
		case double(_ value: Double)
		case int(_ value: Int)
		case string(_ value: String)
		case url(_ value: URL)
		case data(_ value: Data)
		case date(_ value: Date)
		case array(_ value: [CodableValue])
		case dictionary(_ value: [String: CodableValue])

		public var rawValue: Any? {
			switch self {
			case .null:
				return nil
			case let .bool(value):
				return value
			case let .float(value):
				return value
			case let .double(value):
				return value
			case let .int(value):
				return value
			case let .string(value):
				return value
			case let .url(value):
				return value
			case let .data(value):
				return value
			case let .date(value):
				return value
			case let .array(value):
				return value.map(\.rawValue)
			case let .dictionary(value):
				return value.mapValues(\.rawValue)
			}
		}

		public init(from decoder: Decoder) throws {
			enum Error: Swift.Error {
				case undecodableValue(decoder: Decoder)
			}

			do {
				let container = try decoder.container(keyedBy: ObjectCodingKeys.self)
				switch try container.decode(ObjectType.self, forKey: .type) {
				case .null:
					self = .null
				case .url:
					self = .url(try URL(string: container.decode(String.self, forKey: .value)).unwrap())
				case .utf8Data:
					self = .data(try Data(container.decode(String.self, forKey: .value).utf8))
				case .binaryData:
					self = .data(try Data(base64Encoded: container.decode(String.self, forKey: .value)).unwrap())
				case .date:
					self = .date(try userDefaultsCodableValueDateFormatter.date(from: container.decode(String.self, forKey: .value)).unwrap())
				}
				return
			} catch {}

			let container = try decoder.singleValueContainer()
			// swiftformat:disable semicolons, braces
			do { self = .bool(try container.decode(Bool.self)); return } catch {}
			do { self = .int(try container.decode(Int.self)); return } catch {}
			do { self = .float(try container.decode(Float.self)); return } catch {}
			do { self = .double(try container.decode(Double.self)); return } catch {}
			do { self = .string(try container.decode(String.self)); return } catch {}
			do { self = .array(try container.decode([CodableValue].self)); return } catch {}
			do { self = .dictionary(try container.decode([String: CodableValue].self)); return } catch {}
			// swiftformat:enable semicolons, braces

			throw Error.undecodableValue(decoder: decoder)
		}

		public func encode(to encoder: Encoder) throws {
			switch self {
			case .null:
				var container = encoder.container(keyedBy: ObjectCodingKeys.self)
				try container.encode(ObjectType.null, forKey: .type)
			case let .bool(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			case let .float(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			case let .double(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			case let .int(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			case let .string(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			case let .url(value):
				var container = encoder.container(keyedBy: ObjectCodingKeys.self)
				try container.encode(ObjectType.url, forKey: .type)
				try container.encode(value.description, forKey: .value)
			case let .data(value):
				var container = encoder.container(keyedBy: ObjectCodingKeys.self)
				do {
					let utf8Value = try String(data: value, encoding: .utf8).unwrap()
					try container.encode(ObjectType.utf8Data, forKey: .type)
					try container.encode(utf8Value, forKey: .value)
				} catch {
					try container.encode(ObjectType.binaryData, forKey: .type)
					try container.encode(value.base64EncodedString(), forKey: .value)
				}
			case let .date(value):
				var container = encoder.container(keyedBy: ObjectCodingKeys.self)
				try container.encode(ObjectType.date, forKey: .type)
				try container.encode(userDefaultsCodableValueDateFormatter.string(from: value), forKey: .value)
			case let .array(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			case let .dictionary(value):
				var container = encoder.singleValueContainer()
				try container.encode(value)
			}
		}
	}

	// swiftlint:disable:next cyclomatic_complexity
	private func codableValue(from value: Any?) throws -> CodableValue {
		enum Error: Swift.Error {
			case unsupportedValue(_ value: Any)
		}

		guard let value = value else { return .null }
		if let value = value as? Bool {
			return .bool(value)
		} else if let value = value as? Int {
			return .int(value)
		} else if let value = value as? Float {
			return .float(value)
		} else if let value = value as? Double {
			return .double(value)
		} else if let value = value as? String {
			return .string(value)
		} else if let value = value as? URL {
			return .url(value)
		} else if let value = value as? Data {
			return .data(value)
		} else if let value = value as? Date {
			return .date(value)
		} else if let value = value as? [Any] {
			return .array(try value.map { try codableValue(from: $0) })
		} else if let value = value as? [String: Any] {
			return .dictionary(try value.mapValues { try codableValue(from: $0) })
		} else {
			throw Error.unsupportedValue(value)
		}
	}

	func codableRepresentation() throws -> [String: CodableValue] {
		return try dictionaryRepresentation().mapValues { try codableValue(from: $0) }
	}

	func setValues(from codableValues: [String: CodableValue]) {
		codableValues.forEach { key, value in
			set(value.rawValue, forKey: key)
		}
	}

	func removeAll() {
		dictionaryRepresentation().keys.forEach {
			removeObject(forKey: $0)
		}
	}
}
