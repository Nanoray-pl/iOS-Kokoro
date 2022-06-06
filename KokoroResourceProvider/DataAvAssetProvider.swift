//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(AVFoundation) && canImport(Combine) && canImport(Foundation)
import AVFoundation
import Combine
import Foundation
import KokoroAsync
import KokoroUtils

public class DataAvAssetProviderFactory: ResourceProviderFactory {
	public init() {}

	public func create(for input: (data: Data, identifier: String, fileExtension: String)) -> AnyResourceProvider<AVAsset> {
		return DataAvAssetProvider(data: input.data, identifier: input.identifier, fileExtension: input.fileExtension).eraseToAnyResourceProvider()
	}
}

public class DataAvAssetProvider: ResourceProvider {
	private let data: Data
	private let dataIdentifier: String
	private let fileExtension: String
	private let queue = DispatchQueue(label: "pl.nanoray.KokoroResourceProvider.DataAvAssetProvider.queue.\(UUID())", attributes: .concurrent)
	private var fileUrl: URL?

	public var identifier: String {
		return "DataAvAssetProvider[identifier: \(dataIdentifier)]"
	}

	public init(data: Data, identifier: String, fileExtension: String) {
		self.data = data
		dataIdentifier = identifier
		self.fileExtension = fileExtension
	}

	deinit {
		if let fileUrl = fileUrl {
			try? FileManager.default.removeItem(at: fileUrl)
		}
	}

	public func resourceAndAwaitTimeMagnitude() -> (resource: AnyPublisher<AVAsset, Error>, awaitTimeMagnitude: AwaitTimeMagnitude?) {
		var instance: DataAvAssetProvider! = self
		return (
			resource: Future.deferred { promise in
				instance.queue.sync {
					if instance.fileUrl == nil {
						do {
							let url = FileManager.default.temporaryDirectory.appendingPathComponent("asset-\(UUID().uuidString).\(instance.fileExtension)")
							try instance.data.write(to: url)
							instance.fileUrl = url
						} catch {
							instance = nil
							promise(.failure(error))
							return
						}
					}

					let fileUrl = instance.fileUrl!
					instance = nil
					promise(.success(AVAsset(url: fileUrl)))
				}
			}
			.eraseToAnyPublisher(),
			awaitTimeMagnitude: .diskAccess
		)
	}

	public static func == (lhs: DataAvAssetProvider, rhs: DataAvAssetProvider) -> Bool {
		return lhs.data == rhs.data
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(data)
	}
}
#endif
