//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import CoreGraphics

public extension CGRect {
	var topLeft: CGPoint {
		return CGPoint(x: minX, y: minY)
	}

	var topRight: CGPoint {
		return CGPoint(x: maxX, y: minY)
	}

	var bottomLeft: CGPoint {
		return CGPoint(x: minX, y: maxY)
	}

	var bottomRight: CGPoint {
		return CGPoint(x: maxX, y: maxY)
	}

	var center: CGPoint {
		return CGPoint(x: origin.x + size.width * 0.5, y: origin.y + size.height * 0.5)
	}

	init(from point1: CGPoint, to point2: CGPoint) {
		let minX = Swift.min(point1.x, point2.x)
		let maxX = Swift.max(point1.x, point2.x)
		let minY = Swift.min(point1.y, point2.y)
		let maxY = Swift.max(point1.y, point2.y)
		let width = maxX - minX
		let height = maxY - minY
		self.init(x: minX, y: minY, width: width, height: height)
	}

	func enlarged(by scalar: CGFloat) -> CGRect {
		return enlarged(by: CGSize(width: scalar, height: scalar))
	}

	func enlarged(by size: CGSize) -> CGRect {
		return CGRect(origin: CGPoint(x: origin.x - size.width * 0.5, y: origin.y - size.height * 0.5), size: self.size + size)
	}

	func shrinked(by scalar: CGFloat) -> CGRect {
		return shrinked(by: CGSize(width: scalar, height: scalar))
	}

	func shrinked(by size: CGSize) -> CGRect {
		let size = CGSize(width: min(size.width, self.size.width), height: min(size.height, self.size.height))
		return enlarged(by: -size)
	}
}

public extension CGPoint {
	static let horizontalMirror = CGPoint(x: -1, y: 1)
	static let verticalMirror = CGPoint(x: 1, y: -1)
	static let onlyWidth = CGPoint(x: 1, y: 0)
	static let onlyHeight = CGPoint(x: 0, y: 1)

	static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
	}

	static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}

	static func * (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
	}

	static prefix func - (point: CGPoint) -> CGPoint {
		return CGPoint(x: -point.x, y: -point.y)
	}

	init(size: CGSize) {
		self.init(x: size.width, y: size.height)
	}

	var length: CGFloat {
		return CGFloat(sqrt(powf(Float(x), 2) + powf(Float(y), 2)))
	}

	var rotation: CGFloat {
		return atan2(y, x)
	}
}

public extension CGSize {
	static let horizontalMirror = CGSize(width: -1, height: 1)
	static let verticalMirror = CGSize(width: 1, height: -1)
	static let onlyWidth = CGSize(width: 1, height: 0)
	static let onlyHeight = CGSize(width: 0, height: 1)

	var min: CGFloat {
		return Swift.min(width, height)
	}

	var max: CGFloat {
		return Swift.max(width, height)
	}

	static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
		return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
	}

	static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
		return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
	}

	static func * (lhs: CGSize, rhs: CGSize) -> CGSize {
		return CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
	}

	static prefix func - (size: CGSize) -> CGSize {
		return CGSize(width: -size.width, height: -size.height)
	}

	init(point: CGPoint) {
		self.init(width: point.x, height: point.y)
	}
}

#if canImport(UIKit)
import UIKit

public extension CGSize {
	init(insets: UIEdgeInsets) {
		self.init(width: insets.horizontal, height: insets.vertical)
	}

	init(insets: NSDirectionalEdgeInsets) {
		self.init(width: insets.horizontal, height: insets.vertical)
	}
}
#endif
