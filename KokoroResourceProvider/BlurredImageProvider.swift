//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine) && canImport(CoreImage) && canImport(UIKit)
import Combine
import CoreImage
import KokoroUtils
import UIKit

public class BlurredImageProviderFactory: ResourceProviderFactory {
	public typealias Input = AnyResourceProvider<UIImage>
	public typealias Resource = UIImage

	private let radius: CGFloat

	public init(radius: CGFloat) {
		self.radius = radius
	}

	public func create(for input: AnyResourceProvider<UIImage>) -> AnyResourceProvider<UIImage> {
		return BlurredImageProvider(wrapping: input, radius: radius).eraseToAnyResourceProvider()
	}
}

public class BlurredImageProvider: ResourceProvider {
	public typealias Resource = UIImage

	private let wrapped: AnyResourceProvider<UIImage>
	private let radius: CGFloat

	public var identifier: String {
		return "BlurredImageProvider[radius: \(radius), value: \(wrapped.identifier)]"
	}

	public init<Wrapped>(wrapping wrapped: Wrapped, radius: CGFloat) where Wrapped: ResourceProvider, Wrapped.Resource == UIImage {
		self.wrapped = wrapped.eraseToAnyResourceProvider()
		self.radius = radius
	}

	public func resource() -> AnyPublisher<UIImage, Error> {
		return wrapped.resource()
			.map { [radius] unprocessedImage in
				let ciInput = unprocessedImage.ciImage!
				let blurFilter = CIFilter(name: "CIGaussianBlur")!.with {
					$0.setValue(ciInput, forKey: kCIInputImageKey)
					$0.setValue(radius, forKey: kCIInputRadiusKey)
				}
				let cropFilter = CIFilter(name: "CICrop")!.with {
					$0.setValue(blurFilter.outputImage!, forKey: kCIInputImageKey)
					$0.setValue(CIVector(cgRect: ciInput.extent), forKey: "inputRectangle")
				}
				let context = CIContext()
				let ciOutput = cropFilter.outputImage!
				let cgImage = context.createCGImage(ciOutput, from: ciOutput.extent)!
				return UIImage(cgImage: cgImage)
			}
			.eraseToAnyPublisher()
	}

	public static func == (lhs: BlurredImageProvider, rhs: BlurredImageProvider) -> Bool {
		return lhs.wrapped == rhs.wrapped && lhs.radius == rhs.radius
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(wrapped)
		hasher.combine(radius)
	}
}
#endif
