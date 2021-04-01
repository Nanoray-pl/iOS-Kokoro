//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public protocol HttpBodyEncoder {
	associatedtype Input

	func encode(_ input: Input) throws -> (contentType: String, body: Data)
}

public final class RawHttpBodyEncoder: HttpBodyEncoder {
	public typealias Input = (contentType: String, body: Data)

	public init() {}

	public func encode(_ input: (contentType: String, body: Data)) throws -> (contentType: String, body: Data) {
		return input
	}
}

public final class JsonHttpBodyEncoder<Input: Encodable>: HttpBodyEncoder {
	private let encoder: JSONEncoder

	public init(encoder: JSONEncoder = .init()) {
		self.encoder = encoder
	}

	public func encode(_ input: Input) throws -> (contentType: String, body: Data) {
		return (contentType: "application/json", body: try encoder.encode(input))
	}
}

public final class MultipartHttpBodyEncoder<Encoder1: HttpBodyEncoder, Encoder2: HttpBodyEncoder>: HttpBodyEncoder {
	public struct Part<T> {
		public let body: T
		public let fileName: String?

		public init(body: T, fileName: String? = nil) {
			self.body = body
			self.fileName = fileName
		}
	}

	public typealias Input = (part1: Part<Encoder1.Input>, part2: Part<Encoder2.Input>)

	private let encoder1: (encoder: Encoder1, name: String)
	private let encoder2: (encoder: Encoder2, name: String)

	public init(encoder1: (encoder: Encoder1, name: String), encoder2: (encoder: Encoder2, name: String)) {
		self.encoder1 = encoder1
		self.encoder2 = encoder2
	}

	private func quoteEscaped(_ string: String) -> String {
		return string.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
	}

	private func append<Encoder: HttpBodyEncoder>(_ part: Part<Encoder.Input>, into data: inout Data, encoder: (encoder: Encoder, name: String)) throws {
		var contentDispositionValues = ["form-data", "name=\"\(quoteEscaped(encoder.name))\""]
		if let fileName = part.fileName {
			contentDispositionValues.append("filename=\"\(quoteEscaped(fileName))\"")
		}
		data.append(contentsOf: "Content-Disposition: \(contentDispositionValues.joined(separator: "; "))\r\n".utf8)

		let encoded = try encoder.encoder.encode(part.body)
		data.append(contentsOf: "Content-Type: \(encoded.contentType)\r\n".utf8)

		data.append(contentsOf: "\r\n".utf8)
		data.append(encoded.body)
	}

	private func append<Encoder: HttpBodyEncoder>(_ part: Part<Encoder.Input>, into data: inout Data, encoder: (encoder: Encoder, name: String), boundary: String) throws {
		data.append(contentsOf: "--\(boundary)\r\n".utf8)
		try append(part, into: &data, encoder: encoder)
		data.append(contentsOf: "\r\n".utf8)
	}

	public func encode(_ input: (part1: Part<Encoder1.Input>, part2: Part<Encoder2.Input>)) throws -> (contentType: String, body: Data) {
		let boundary = UUID().uuidString
		var data: Data = .init()

		try append(input.part1, into: &data, encoder: encoder1, boundary: boundary)
		try append(input.part2, into: &data, encoder: encoder2, boundary: boundary)
		data.append(contentsOf: "--\(boundary)--".utf8)

		return (contentType: "multipart/form-data; boundary=\(boundary)", body: data)
	}
}
#endif
