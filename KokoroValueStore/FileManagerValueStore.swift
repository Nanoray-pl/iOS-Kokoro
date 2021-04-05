//
//  Created on 05/04/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import Foundation
import KokoroUtils

public class FileManagerValueStore<Element: Codable>: ThrowingValueStore {
	private let fileManager: FileManager
	private let url: URL
	private let getter: (_ fileManager: FileManager, _ url: URL) throws -> Element
	private let setter: (_ fileManager: FileManager, _ url: URL, _ value: Element) throws -> Void

	public init(
		fileManager: FileManager = .default,
		url: URL,
		getter: @escaping (_ fileManager: FileManager, _ url: URL) throws -> Element,
		setter: @escaping (_ fileManager: FileManager, _ url: URL, _ value: Element) throws -> Void
	) {
		self.fileManager = fileManager
		self.url = url
		self.getter = getter
		self.setter = setter
	}

	public func value() throws -> Element {
		return try getter(fileManager, url)
	}

	public func setValue(_ value: Element) throws {
		try setter(fileManager, url, value)
	}
}

public extension FileManagerValueStore where Element: OptionalConvertible, Element.Wrapped: Codable {
	convenience init(fileManager: FileManager = .default, url: URL, encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
		self.init(
			fileManager: fileManager,
			url: url,
			getter: { fileManager, url in
				if fileManager.fileExists(atPath: url.absoluteString) {
					return try decoder.decode(Element.self, from: Data(contentsOf: url))
				} else {
					return .init(from: nil)
				}
			},
			setter: { fileManager, url, value in
				if let value = value.optional() {
					let data = try encoder.encode(value)
					try data.write(to: url)
				} else {
					if fileManager.fileExists(atPath: url.absoluteString) {
						try fileManager.removeItem(at: url)
					}
				}
			}
		)
	}
}
