//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public extension UIEdgeInsets {
	var horizontal: CGFloat {
		return left + right
	}

	var vertical: CGFloat {
		return top + bottom
	}

	init(insets: CGFloat) {
		self.init(top: insets, left: insets, bottom: insets, right: insets)
	}
}

public extension NSDirectionalEdgeInsets {
	var horizontal: CGFloat {
		return leading + trailing
	}

	var vertical: CGFloat {
		return top + bottom
	}
}
#endif
