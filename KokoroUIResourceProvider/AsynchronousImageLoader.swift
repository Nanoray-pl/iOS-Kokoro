//
//  Created on 22/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(UIKit)
import Combine
import KokoroResourceProvider
import KokoroUI
import KokoroUtils
import UIKit

public protocol AsynchronousImageLoaderTarget: AnyObject {
	var image: UIImage? { get set }

	func addSubview(_ subview: UIView)
	func insertSubview(_ subview: UIView, at index: Int)
}

extension UIImageView: AsynchronousImageLoaderTarget {}
extension RatioImageView: AsynchronousImageLoaderTarget {}

public protocol AsynchronousImageLoader: AnyObject {
	func loadImage<T>(from provider: T?, into target: AsynchronousImageLoaderTarget, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)?) where T: ResourceProvider, T.Resource == UIImage?
}

public extension AsynchronousImageLoader {
	func loadImage<T>(from provider: T?, into target: AsynchronousImageLoaderTarget, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>, successCallback: ((UIImage?) -> Void)? = nil) where T: ResourceProvider, T.Resource == UIImage {
		let provider: AnyResourceProvider<UIImage?>? = provider.flatMap { (provider: T) -> AnyResourceProvider<UIImage?> in MapResourceProvider(wrapping: provider, identifier: PrivateSourceLocation().description, mapFunction: .init { $0 }).eraseToAnyResourceProvider() }
		let errorHandler: (Error) -> AnyPublisher<UIImage?, Never> = { errorHandler($0).map { $0 }.eraseToAnyPublisher() }
		loadImage(from: provider, into: target, errorHandler: errorHandler, successCallback: successCallback)
	}

	func loadImage<T>(from provider: T?, into target: AsynchronousImageLoaderTarget, errorHandler: @escaping (Error) -> AnyPublisher<UIImage?, Never>) where T: ResourceProvider, T.Resource == UIImage? {
		loadImage(from: provider, into: target, errorHandler: errorHandler, successCallback: nil)
	}

	func loadImage<T>(from provider: T?, into target: AsynchronousImageLoaderTarget, logger: Logger, placeholder: UIImage? = nil, file: String = #file, function: String = #function, line: Int = #line, successCallback: ((UIImage?) -> Void)? = nil) where T: ResourceProvider, T.Resource == UIImage? {
		loadImage(
			from: provider,
			into: target,
			errorHandler: {
				logger.warning("Failed to load image: \($0)", file: file, function: function, line: line)
				return Just(placeholder).eraseToAnyPublisher()
			},
			successCallback: successCallback
		)
	}

	func loadImage<T>(from provider: T?, into target: AsynchronousImageLoaderTarget, logger: Logger, placeholder: UIImage? = nil, file: String = #file, function: String = #function, line: Int = #line, successCallback: ((UIImage?) -> Void)? = nil) where T: ResourceProvider, T.Resource == UIImage {
		loadImage(
			from: provider,
			into: target,
			errorHandler: {
				logger.warning("Failed to load image: \($0)", file: file, function: function, line: line)
				return Just(placeholder).eraseToAnyPublisher()
			},
			successCallback: successCallback
		)
	}
}
#endif
