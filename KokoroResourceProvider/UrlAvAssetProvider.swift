//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(AVFoundation) && canImport(Combine) && canImport(Foundation)
import AVFoundation
import Combine
import Foundation

public class UrlAvAssetProviderFactory: ResourceProviderFactory {
	public init() {}

	public func create(for input: URL) -> AnyResourceProvider<AVAsset> {
		return UrlAvAssetProvider(url: input).eraseToAnyResourceProvider()
	}
}

public class UrlAvAssetProvider: ResourceProvider {
	private let url: URL

	public var identifier: String {
		return "UrlAvAssetProvider[url: \(url)]"
	}

	public init(url: URL) {
		self.url = url
	}

	public func resource() -> AnyPublisher<AVAsset, Error> {
		return Just(AVAsset(url: url))
			.setFailureType(to: Error.self)
			.eraseToAnyPublisher()
	}

	public static func == (lhs: UrlAvAssetProvider, rhs: UrlAvAssetProvider) -> Bool {
		return lhs.url == rhs.url
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(url)
	}
}
#endif
