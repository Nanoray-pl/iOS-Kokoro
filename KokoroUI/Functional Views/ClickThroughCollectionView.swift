//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public class ClickThroughCollectionView: UICollectionView {
	public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		if let result = super.hitTest(point, with: event) {
			var current: UIView? = result
			while current != nil {
				if let current = current as? UICollectionViewCell, visibleCells.contains(current) {
					return result
				}
				if current == self {
					break
				}
				current = current?.superview
			}
			return nil
		} else {
			return nil
		}
	}
}
#endif
