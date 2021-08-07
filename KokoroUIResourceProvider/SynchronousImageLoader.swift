//
//  Created on 07/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(UIKit)
import Combine
import KokoroResourceProvider
import UIKit

public class SynchronousImageLoader: AsynchronousImageLoader {
	public init() {}

	public func loadImage<T>(from provider: T?, into target: AsynchronousImageLoaderTarget, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)?) where T: ResourceProvider, T.Resource == UIImage? {
		switch provider?.resource().catch(errorHandler).syncResult() {
		case let .success(image):
			target.image = image
			successCallback?(image)
		case let .failure(error):
			_ = errorHandler(error)
		case nil:
			target.image = nil
			successCallback?(nil)
		}
	}
}
#endif
