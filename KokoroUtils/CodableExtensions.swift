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

#if canImport(Combine)
import Combine

public typealias TopLevelDecoder = Combine.TopLevelDecoder
public typealias TopLevelEncoder = Combine.TopLevelEncoder
#else
public protocol TopLevelDecoder {
	associatedtype Input

	func decode<T: Decodable>(_ type: T.Type, from input: Input) throws -> T
}

public protocol TopLevelEncoder {
	associatedtype Output

	func encode<T: Encodable>(_ value: T) throws -> Output
}

#if canImport(Foundation)
import Foundation

extension JSONDecoder: TopLevelDecoder {}
extension JSONEncoder: TopLevelEncoder {}

extension PropertyListDecoder: TopLevelDecoder {}
extension PropertyListEncoder: TopLevelEncoder {}
#endif
#endif

private class AnyTopLevelDecoderBase<Input>: TopLevelDecoder {
	func decode<T: Decodable>(_ type: T.Type, from input: Input) throws -> T {
		fatalError("Not overriden abstract member")
	}
}

private class AnyTopLevelDecoderBaseBox<Wrapped>: AnyTopLevelDecoderBase<Wrapped.Input> where Wrapped: TopLevelDecoder {
	typealias Input = Wrapped.Input

	private let wrapped: Wrapped

	init(wrapping wrapped: Wrapped) {
		self.wrapped = wrapped
	}

	override func decode<T: Decodable>(_ type: T.Type, from input: Input) throws -> T {
		return try wrapped.decode(type, from: input)
	}
}

public final class AnyTopLevelDecoder<Input>: TopLevelDecoder {
	private let box: AnyTopLevelDecoderBase<Input>

	public init<T>(wrapping wrapped: T) where T: TopLevelDecoder, T.Input == Input {
		box = AnyTopLevelDecoderBaseBox(wrapping: wrapped)
	}

	public func decode<T: Decodable>(_ type: T.Type, from input: Input) throws -> T {
		return try box.decode(type, from: input)
	}
}

public extension TopLevelDecoder {
	func eraseToAnyTopLevelDecoder() -> AnyTopLevelDecoder<Input> {
		return (self as? AnyTopLevelDecoder<Input>) ?? .init(wrapping: self)
	}
}

private class AnyTopLevelEncoderBase<Output>: TopLevelEncoder {
	func encode<T: Encodable>(_ value: T) throws -> Output {
		fatalError("Not overriden abstract member")
	}
}

private class AnyTopLevelEncoderBaseBox<Wrapped>: AnyTopLevelEncoderBase<Wrapped.Output> where Wrapped: TopLevelEncoder {
	typealias Output = Wrapped.Output

	private let wrapped: Wrapped

	init(wrapping wrapped: Wrapped) {
		self.wrapped = wrapped
	}

	override func encode<T: Encodable>(_ value: T) throws -> Output {
		return try wrapped.encode(value)
	}
}

public final class AnyTopLevelEncoder<Output>: TopLevelEncoder {
	private let box: AnyTopLevelEncoderBase<Output>

	public init<T>(wrapping wrapped: T) where T: TopLevelEncoder, T.Output == Output {
		box = AnyTopLevelEncoderBaseBox(wrapping: wrapped)
	}

	public func encode<T: Encodable>(_ value: T) throws -> Output {
		return try box.encode(value)
	}
}

public extension TopLevelEncoder {
	func eraseToAnyTopLevelEncoder() -> AnyTopLevelEncoder<Output> {
		return (self as? AnyTopLevelEncoder<Output>) ?? .init(wrapping: self)
	}
}
