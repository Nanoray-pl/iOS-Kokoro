//
//  Created on 22/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(UIKit)
import Combine
import KokoroUtils
import KokoroResourceProvider
import UIKit

public protocol AsynchronousImageLoader: class {
	func loadImage<T>(from provider: T?, into imageView: UIImageView, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)?) where T: ResourceProvider, T.Resource == UIImage?
}

public extension AsynchronousImageLoader {
	func loadImage<T>(from provider: T?, into imageView: UIImageView, errorHandler: @escaping (Error) -> AnyPublisher<UIImage, Never>, successCallback: ((UIImage?) -> Void)? = nil) where T: ResourceProvider, T.Resource == UIImage {
		let provider: AnyResourceProvider<UIImage?>? = provider.flatMap { (provider: T) -> AnyResourceProvider<UIImage?> in MapResourceProvider(wrapping: provider, identifier: PrivateSourceLocation().description, mapFunction: .init { $0 }).eraseToAnyResourceProvider() }
		let errorHandler: (Error) -> AnyPublisher<UIImage?, Never> = { errorHandler($0).map { $0 }.eraseToAnyPublisher() }
		loadImage(from: provider, into: imageView, errorHandler: errorHandler, successCallback: successCallback)
	}

	func loadImage<T>(from provider: T?, into imageView: UIImageView, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)? = nil) where T: ResourceProvider, T.Resource == UIImage? {
		loadImage(from: provider, into: imageView, errorHandler: errorHandler, successCallback: successCallback)
	}

	func loadImage<T>(from provider: T?, into imageView: UIImageView, logger: Logger, placeholder: UIImage, file: String = #file, function: String = #function, line: Int = #line, successCallback: ((UIImage?) -> Void)? = nil) where T: ResourceProvider, T.Resource == UIImage? {
		loadImage(
			from: provider,
			into: imageView,
			errorHandler: {
				logger.warning("Failed to load image: \($0)", file: file, function: function, line: line)
				return Just(placeholder).eraseToAnyPublisher()
			},
			successCallback: successCallback
		)
	}

	func loadImage<T>(from provider: T?, into imageView: UIImageView, logger: Logger, placeholder: UIImage, file: String = #file, function: String = #function, line: Int = #line, successCallback: ((UIImage?) -> Void)? = nil) where T: ResourceProvider, T.Resource == UIImage {
		loadImage(
			from: provider,
			into: imageView,
			errorHandler: {
				logger.warning("Failed to load image: \($0)", file: file, function: function, line: line)
				return Just(placeholder).eraseToAnyPublisher()
			},
			successCallback: successCallback
		)
	}
}
#endif
