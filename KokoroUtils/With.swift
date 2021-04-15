//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public protocol AnyWith {}
public protocol ValueWith: AnyWith {}

public protocol ObjectWith: class, AnyWith {
	typealias Proxy<T> = AnyProxy<Self, T>
}

private enum CastError: Error {
	case error
}

public extension AnyWith {
	func takeIf(_ block: (Self) throws -> Bool) rethrows -> Self? {
		return try block(self) ? self : nil
	}

	func cast<NewType>(to newType: NewType.Type) throws -> NewType {
		if let result = self as? NewType {
			return result
		} else {
			throw CastError.error
		}
	}
}

public extension ObjectWith {
	@discardableResult
	func with(_ block: (Self) throws -> Void) rethrows -> Self {
		try block(self)
		return self
	}
}

public extension ValueWith {
	func with(_ block: (inout Self) throws -> Void) rethrows -> Self {
		var copy = self
		try block(&copy)
		return copy
	}
}

public extension Sequence where Element: ObjectWith {
	@discardableResult
	func withEach(_ block: (Element) throws -> Void) rethrows -> Self {
		try forEach { try $0.with(block) }
		return self
	}
}

public extension Sequence where Element: ValueWith {
	func withEach(_ block: (inout Element) throws -> Void) rethrows -> [Element] {
		return try map { try $0.with(block) }
	}
}

extension Bool: ValueWith {}
extension Int: ValueWith {}
extension Float: ValueWith {}
extension Double: ValueWith {}
extension Decimal: ValueWith {}
extension String: ValueWith {}
extension Array: ValueWith {}
extension Dictionary: ValueWith {}
extension Optional: ValueWith {}

#if canImport(ObjectiveC)
import ObjectiveC

extension NSObject: ObjectWith {}
#endif

#if canImport(Foundation)
import Foundation

extension URLRequest: ValueWith {}
extension Date: ValueWith {}
extension DateComponents: ValueWith {}
#endif

#if canImport(CoreGraphics)
import CoreGraphics

extension CGRect: ValueWith {}
extension CGPoint: ValueWith {}
extension CGVector: ValueWith {}
extension CGPath: ValueWith {}
extension CGSize: ValueWith {}
extension CGAffineTransform: ValueWith {}
#endif

#if canImport(QuartzCore)
import QuartzCore

extension CATransform3D: ValueWith {}
#endif

#if canImport(UIKit)
import UIKit

@available(iOS 14, *)
extension NSDiffableDataSourceSectionSnapshot: ValueWith {}

extension NSDiffableDataSourceSnapshot: ValueWith {}
#endif
