//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation
import KokoroAsync

public class UrlDataProviderFactory: ResourceProviderFactory {
	private let session: URLSession

	public init(session: URLSession) {
		self.session = session
	}

	public func create(for input: URL) -> AnyResourceProvider<Data> {
		if input.isFileURL {
			return LocalUrlDataProvider(url: input).eraseToAnyResourceProvider()
		} else {
			return UrlDataProvider(session: session, url: input).eraseToAnyResourceProvider()
		}
	}
}

public class UrlDataProvider: ResourceProvider {
	private let session: URLSession
	private let url: URL

	public var identifier: String {
		return "UrlDataProvider[url: \(url)]"
	}

	public init(session: URLSession, url: URL) {
		self.session = session
		self.url = url
	}

	public func resourceAndAwaitTimeMagnitude() -> (resource: AnyPublisher<Data, Error>, awaitTimeMagnitude: AwaitTimeMagnitude?) {
		enum Error: Swift.Error {
			case noData
		}

		return (
			resource: session.dataTaskPublisher(for: url)
				// swiftformat:disable:next preferKeyPath
				.map { $0.data }
				.mapError { $0 as Swift.Error }
				.replaceNilWithError(Error.noData)
				.eraseToAnyPublisher(),
			awaitTimeMagnitude: .networkAccess
		)
	}

	public static func == (lhs: UrlDataProvider, rhs: UrlDataProvider) -> Bool {
		return lhs.session == rhs.session && lhs.url == rhs.url
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(url)
	}
}
#endif
