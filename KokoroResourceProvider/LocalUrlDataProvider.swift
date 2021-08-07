//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class LocalUrlDataProviderFactory: ResourceProviderFactory {
	public init() {}

	public func create(for input: URL) -> AnyResourceProvider<Data> {
		return LocalUrlDataProvider(url: input).eraseToAnyResourceProvider()
	}
}

public class LocalUrlDataProvider: ResourceProvider {
	enum Error: Swift.Error {
		case notLocal
	}

	public let url: URL

	public var identifier: String {
		return "LocalUrlDataProvider[url: \(url)]"
	}

	public init(url: URL) {
		self.url = url
	}

	public func resourceAndAwaitTimeMagnitude() -> (resource: AnyPublisher<Data, Swift.Error>, awaitTimeMagnitude: AwaitTimeMagnitude?) {
		let publisher: AnyPublisher<Data, Swift.Error>
		if url.isFileURL {
			publisher = Deferred { [url] () -> AnyPublisher<Data, Swift.Error> in
				do {
					return Just(try Data(contentsOf: url))
						.setFailureType(to: Swift.Error.self)
						.eraseToAnyPublisher()
				} catch {
					return Fail(error: error)
						.eraseToAnyPublisher()
				}
			}
			.eraseToAnyPublisher()
		} else {
			publisher = Fail(error: Error.notLocal)
				.eraseToAnyPublisher()
		}
		return (
			resource: publisher,
			awaitTimeMagnitude: .diskAccess
		)
	}

	public static func == (lhs: LocalUrlDataProvider, rhs: LocalUrlDataProvider) -> Bool {
		return lhs.url == rhs.url
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(url)
	}
}
#endif
