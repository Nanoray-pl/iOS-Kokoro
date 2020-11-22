//
//  Created on 22/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(UIKit)
import Combine
import KokoroResourceProvider
import UIKit

public class SimpleAsynchronousImageLoader: AsynchronousImageLoader {
	private let cancellables = NSMapTable<UIImageView, Combine.AnyCancellable>(keyOptions: .weakMemory, valueOptions: .strongMemory)

	public func loadImage<T>(from provider: T?, into imageView: UIImageView, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)?) where T: ResourceProvider, T.Resource == UIImage? {
		cancellables.object(forKey: imageView)?.cancel()
		guard let provider = provider else {
			imageView.image = nil
			cancellables.removeObject(forKey: imageView)
			return
		}

		let publisher = provider.resource()
		let cancellable = publisher
			.buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
			.receive(on: DispatchQueue.main)
			.catch(errorHandler)
			.onCancel { [weak cancellables, weak imageView] in
				cancellables?.removeObject(forKey: imageView)
			}
			.sink(
				receiveCompletion: { [weak cancellables, weak imageView] _ in
					cancellables?.removeObject(forKey: imageView)
				},
				receiveValue: { [weak imageView] image in
					imageView?.image = image
					successCallback?(image)
				}
			)
		cancellables.setObject(cancellable, forKey: imageView)
	}
}
#endif
