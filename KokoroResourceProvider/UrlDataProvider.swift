//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(Foundation)
import Combine
import Foundation

public class UrlDataProviderFactory: ResourceProviderFactory {
	public typealias Input = URL
	public typealias Resource = Data

	private let session: URLSession

	public init(session: URLSession) {
		self.session = session
	}

	public func create(for input: URL) -> AnyResourceProvider<Resource> {
		if input.isFileURL {
			return LocalUrlDataProvider(url: input).eraseToAnyResourceProvider()
		} else {
			return UrlDataProvider(session: session, url: input).eraseToAnyResourceProvider()
		}
	}
}

public class UrlDataProvider: ResourceProvider {
	public typealias Resource = Data

	private let session: URLSession
	private let url: URL

	public var identifier: String {
		return "UrlDataProvider[url: \(url)]"
	}

	public init(session: URLSession, url: URL) {
		self.session = session
		self.url = url
	}

	public func resource() -> AnyPublisher<Data, Error> {
		enum Error: Swift.Error {
			case noData
		}

		return session.dataTaskPublisher(for: url)
			.map(\.data)
			.mapError { $0 as Swift.Error }
			.eraseToAnyPublisher()
	}

	public static func == (lhs: UrlDataProvider, rhs: UrlDataProvider) -> Bool {
		return lhs.session == rhs.session && lhs.url == rhs.url
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(url)
	}
}
#endif
