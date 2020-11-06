//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

public extension Comparable {
	func clamped(to range: ClosedRange<Self>) -> Self {
		if self < range.lowerBound {
			return range.lowerBound
		} else if self > range.upperBound {
			return range.upperBound
		} else {
			return self
		}
	}
}

public extension Comparable where Self: FloatingPoint {
	func reverse(in range: ClosedRange<Self>) -> Self {
		let coefficient = (self - range.lowerBound) / (range.upperBound - range.lowerBound)
		return range.lowerBound + (range.upperBound - range.lowerBound) * (1 - coefficient)
	}

	/// Re-maps this value from the `oldRange` to a `newRange`, that is, a value of `oldRange.lowerBound` results in `newRange.lowerBound`, `oldRange.upperBound` results in`newRange.upperBound`, and anything else results in appropriately mapped values in-between.
	func mapped(from oldRange: ClosedRange<Self>, to newRange: ClosedRange<Self>) -> Self {
		let coefficient = (self - oldRange.lowerBound) / (oldRange.upperBound - oldRange.lowerBound)
		return newRange.lowerBound + (newRange.upperBound - newRange.lowerBound) * coefficient
	}
}
