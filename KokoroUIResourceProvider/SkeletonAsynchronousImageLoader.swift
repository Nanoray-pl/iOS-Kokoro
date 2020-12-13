//
//  Created on 22/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(UIKit)
import Combine
import KokoroResourceProvider
import KokoroUI
import UIKit

public class SkeletonAsynchronousImageLoader: AsynchronousImageLoader {
	private let skeletonFactory: () -> SkeletonView

	private struct Entry {
		private(set) weak var target: AsynchronousImageLoaderTarget?
		let cancellable: Combine.AnyCancellable
		let skeleton: SkeletonView
	}

	private var entries = [Entry]() {
		didSet {
			guard entries.contains(where: { $0.target == nil }) else { return }
			entries = entries.filter { $0.target != nil }
		}
	}

	public init(skeletonFactory: @escaping () -> SkeletonView = { .init() }) {
		self.skeletonFactory = skeletonFactory
	}

	private func cleanUp(for target: AsynchronousImageLoaderTarget) {
		if let entry = entries.first(where: { $0.target === target }) {
			entry.cancellable.cancel()
			entry.skeleton.removeFromSuperview()
			entries.removeFirst { $0.target === target }
		}
	}

	public func loadImage<T>(from provider: T?, into target: AsynchronousImageLoaderTarget, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)?) where T: ResourceProvider, T.Resource == UIImage? {
		cleanUp(for: target)
		guard let provider = provider else {
			target.image = nil
			return
		}

		let skeleton = skeletonFactory()
		target.insertSubview(skeleton, at: 0)
		skeleton.edgesToSuperview().activate()

		let publisher = provider.resource()
		let cancellable = publisher
			.receive(on: DispatchQueue.main)
			.catch(errorHandler)
			.onCancel { [weak self, weak target] in
				guard let self = self, let target = target else { return }
				self.cleanUp(for: target)
			}
			.sink(
				receiveCompletion: { [weak self, weak target] _ in
					guard let self = self, let target = target else { return }
					self.cleanUp(for: target)
				},
				receiveValue: { [weak target] image in
					target?.image = image
					successCallback?(image)
				}
			)
		entries.append(.init(target: target, cancellable: cancellable, skeleton: skeleton))
	}
}
#endif
