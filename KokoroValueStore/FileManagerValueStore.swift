//
//  Created on 05/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import Foundation
import KokoroUtils

public class FileManagerValueStore<CodableElement: Codable>: ThrowingValueStore {
	public typealias Element = CodableElement?

	private let fileManager: FileManager
	private let url: URL
	private let decoder: AnyTopLevelDecoder<Data>
	private let encoder: AnyTopLevelEncoder<Data>

	public init<Decoder, Encoder>(fileManager: FileManager = .default, url: URL, decoder: Decoder, encoder: Encoder) where Decoder: TopLevelDecoder, Decoder.Input == Data, Encoder: TopLevelEncoder, Encoder.Output == Data {
		self.fileManager = fileManager
		self.url = url
		self.decoder = decoder.eraseToAnyTopLevelDecoder()
		self.encoder = encoder.eraseToAnyTopLevelEncoder()
	}

	public func value() throws -> CodableElement? {
		if fileManager.fileExists(atPath: url.path) {
			return try decoder.decode(Element.self, from: Data(contentsOf: url))
		} else {
			return nil
		}
	}

	public func setValue(_ value: CodableElement?) throws {
		if let value = value {
			let data = try encoder.encode(value)
			try data.write(to: url)
		} else {
			if fileManager.fileExists(atPath: url.path) {
				try fileManager.removeItem(at: url)
			}
		}
	}
}
