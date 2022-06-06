//
//  Created on 07/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(UIKit)
import Combine
import KokoroResourceProvider
import UIKit

public class AwaitTimeMagnitudeAwareAsynchronousImageLoader: AsynchronousImageLoader {
	private struct Entry {
		private(set) weak var target: AsynchronousImageLoaderTarget?
		private(set) weak var loader: AsynchronousImageLoader?
	}

	private let awaitTimeMagnitudeLoaders: [(excludedMax: AwaitTimeMagnitude, loader: AsynchronousImageLoader)]
	private let fallbackLoader: AsynchronousImageLoader

	private var entries = [Entry]() {
		didSet {
			guard entries.contains(where: { $0.target == nil || $0.loader == nil }) else { return }
			entries = entries.filter { $0.target != nil && $0.loader != nil }
		}
	}

	public init(awaitTimeMagnitudeLoaders: [(excludedMax: AwaitTimeMagnitude, loader: AsynchronousImageLoader)], fallbackLoader: AsynchronousImageLoader) {
		self.awaitTimeMagnitudeLoaders = awaitTimeMagnitudeLoaders.sorted(by: \.excludedMax)
		self.fallbackLoader = fallbackLoader
	}

	public func loadImage<T>(from provider: T?, into target: AsynchronousImageLoaderTarget, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)?) where T: ResourceProvider, T.Resource == UIImage? {
		entries.removeFirst { $0.target === target }?.loader?.loadImage(from: nil as T?, into: target, errorHandler: errorHandler, successCallback: successCallback)

		guard let provider = provider else { return }
		let result = provider.resourceAndAwaitTimeMagnitude()

		if let awaitTimeMagnitude = result.awaitTimeMagnitude {
			for awaitTimeMagnitudeLoader in awaitTimeMagnitudeLoaders where awaitTimeMagnitude < awaitTimeMagnitudeLoader.excludedMax {
				entries.append(.init(target: target, loader: awaitTimeMagnitudeLoader.loader))
				awaitTimeMagnitudeLoader.loader.loadImage(from: provider, into: target, errorHandler: errorHandler, successCallback: successCallback)
				return
			}
		}

		entries.append(.init(target: target, loader: fallbackLoader))
		fallbackLoader.loadImage(from: provider, into: target, errorHandler: errorHandler, successCallback: successCallback)
	}
}
#endif
