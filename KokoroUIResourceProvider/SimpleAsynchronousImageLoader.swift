//
//  Created on 22/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(UIKit)
import Combine
import KokoroResourceProvider
import UIKit

public class SimpleAsynchronousImageLoader: AsynchronousImageLoader {
	private struct Entry {
		private(set) weak var target: AsynchronousImageLoaderTarget?
		let cancellable: Combine.AnyCancellable
	}

	private var entries = [Entry]() {
		didSet {
			guard entries.contains(where: { $0.target == nil }) else { return }
			entries = entries.filter { $0.target != nil }
		}
	}

	public func loadImage<T>(from provider: T?, into target: AsynchronousImageLoaderTarget, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)?) where T : ResourceProvider, T.Resource == UIImage? {
		entries.first { $0.target === target }?.cancellable.cancel()
		guard let provider = provider else {
			target.image = nil
			entries.removeFirst { $0.target === target }
			return
		}

		let publisher = provider.resource()
		let cancellable = publisher
			.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
			.receive(on: DispatchQueue.main)
			.catch(errorHandler)
			.onCancel { [weak self, weak target] in
				self?.entries.removeFirst { $0.target === target }
			}
			.sink(
				receiveCompletion: { [weak self, weak target] _ in
					self?.entries.removeFirst { $0.target === target }
				},
				receiveValue: { [weak target] image in
					target?.image = image
					successCallback?(image)
				}
			)
		entries.append(.init(target: target, cancellable: cancellable))
	}
}
#endif
