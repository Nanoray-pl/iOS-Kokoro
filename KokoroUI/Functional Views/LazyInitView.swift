//
//  Created on 23/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

open class LazyInitView: UIView {
	public private(set) var isInitialized = false

	open override func didMoveToWindow() {
		super.didMoveToWindow()
		if !isInitialized && window != nil {
			isInitialized = true
			initializeView()
		}
	}

	/// Tells the view that it moved to a window for the first time and that it should initialize any of its lazily initializable contents.
	open func initializeView() {}
}
#endif
