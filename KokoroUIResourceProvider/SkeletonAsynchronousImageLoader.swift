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

	private var cancellables = Set<Combine.AnyCancellable>()
	private let imageToCancellable = NSMapTable<UIImageView, Combine.AnyCancellable>(keyOptions: .weakMemory, valueOptions: .weakMemory)
	private let imageToSkeleton = NSMapTable<UIImageView, SkeletonView>(keyOptions: .weakMemory, valueOptions: .weakMemory)

	public init(skeletonFactory: @escaping () -> SkeletonView = { .init() }) {
		self.skeletonFactory = skeletonFactory
	}

	private func cleanUp(for imageView: UIImageView) {
		if let cancellable = imageToCancellable.object(forKey: imageView) {
			cancellable.cancel()
			cancellables.remove(cancellable)
			imageToCancellable.removeObject(forKey: imageView)

			imageToSkeleton.object(forKey: imageView)?.removeFromSuperview()
			imageToSkeleton.removeObject(forKey: imageView)
		}
	}

	public func loadImage<T>(from provider: T?, into imageView: UIImageView, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)?) where T: ResourceProvider, T.Resource == UIImage? {
		cleanUp(for: imageView)
		guard let provider = provider else {
			imageView.image = nil
			return
		}

		let skeleton = skeletonFactory()
		imageView.insertSubview(skeleton, at: 0)
		skeleton.edgesToSuperview().activate()

		let publisher = provider.resource()
		let cancellable = publisher
			.receive(on: DispatchQueue.main)
			.catch(errorHandler)
			.onCancel { [weak self, weak imageView] in
				guard let self = self, let imageView = imageView else { return }
				self.cleanUp(for: imageView)
			}
			.sink(
				receiveCompletion: { [weak self, weak imageView] _ in
					guard let self = self, let imageView = imageView else { return }
					self.cleanUp(for: imageView)
				},
				receiveValue: { [weak imageView] image in
					imageView?.image = image
					successCallback?(image)
				}
			)

		cancellables.insert(cancellable)
		imageToCancellable.setObject(cancellable, forKey: imageView)
		imageToSkeleton.setObject(skeleton, forKey: imageView)
	}
}
#endif
