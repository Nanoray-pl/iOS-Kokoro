//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(AVFoundation) && canImport(Combine) && canImport(Foundation)
import AVFoundation
import Combine
import Foundation

public class DataAvAssetProviderFactory: ResourceProviderFactory {
	public typealias Input = (data: Data, identifier: String)
	public typealias Resource = AVAsset

	public func create(for input: Input) -> AnyResourceProvider<AVAsset> {
		return DataAvAssetProvider(data: input.data, identifier: input.identifier).eraseToAnyResourceProvider()
	}
}

public class DataAvAssetProvider: ResourceProvider {
	public typealias Resource = AVAsset

	private let data: Data
	private let dataIdentifier: String
	private let queue = DispatchQueue(label: "uk.os.SecretStories.DataAvAssetProvider.queue", attributes: .concurrent)
	private var fileUrl: URL?

	public var identifier: String {
		return "DataAvAssetProvider[identifier: \(dataIdentifier)]"
	}

	public init(data: Data, identifier: String) {
		self.data = data
		dataIdentifier = identifier
	}

	deinit {
		if let fileUrl = fileUrl {
			try? FileManager.default.removeItem(at: fileUrl)
		}
	}

	public func resource() -> AnyPublisher<AVAsset, Error> {
		var instance: DataAvAssetProvider! = self
		return Deferred {
			return Future { promise in
				instance.queue.sync {
					if instance.fileUrl == nil {
						do {
							let url = FileManager.default.temporaryDirectory.appendingPathComponent("asset-\(UUID().uuidString)")
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
		}
		.eraseToAnyPublisher()
	}

	public static func == (lhs: DataAvAssetProvider, rhs: DataAvAssetProvider) -> Bool {
		return lhs.data == rhs.data
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(data)
	}
}
#endif
