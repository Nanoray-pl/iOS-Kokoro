//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

private var observersKey: UInt8 = 0

@objc public protocol UIViewSubviewObserver: class, NSObjectProtocol {
	func didAddSubview(_ subview: UIView, to view: UIView)
	func didRemoveSubview(_ subview: UIView, from view: UIView)
}

private enum HierarchyObserving {
	private static var swizzled = false

	static func swizzle() {
		if swizzled { return }

		do {
			let original = class_getInstanceMethod(UIView.self, #selector(UIView.didAddSubview(_:)))!
			let swizzled = class_getInstanceMethod(UIView.self, #selector(UIView.swizzledDidAddSubview(_:)))!
			method_exchangeImplementations(original, swizzled)
		}

		do {
			let original = class_getInstanceMethod(UIView.self, #selector(UIView.removeFromSuperview))!
			let swizzled = class_getInstanceMethod(UIView.self, #selector(UIView.swizzledRemoveFromSuperview))!
			method_exchangeImplementations(original, swizzled)
		}

		swizzled = true
	}
}

public extension UIView {
	private var observers: NSHashTable<UIViewSubviewObserver>? {
		get {
			return objc_getAssociatedObject(self, &observersKey) as? NSHashTable<UIViewSubviewObserver>
		}
		set {
			objc_setAssociatedObject(self, &observersKey, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}

	private func setupObservers() -> NSHashTable<UIViewSubviewObserver> {
		if let observers = observers {
			return observers
		} else {
			let observers = NSHashTable<UIViewSubviewObserver>(options: .weakMemory)
			self.observers = observers
			return observers
		}
	}

	func addSubviewObserver(_ observer: UIViewSubviewObserver) {
		HierarchyObserving.swizzle()
		let observers = setupObservers()
		observers.add(observer)
	}

	func removeSubviewObserver(_ observer: UIViewSubviewObserver) {
		guard let observers = observers else { return }
		observers.remove(observer)
	}

	@objc fileprivate func swizzledDidAddSubview(_ subview: UIView) {
		// calling itself, but because of swizzling this calls the real method
		swizzledDidAddSubview(subview)
		observers?.allObjects.forEach { $0.didAddSubview(subview, to: self) }
	}

	@objc fileprivate func swizzledRemoveFromSuperview() {
		// calling itself, but because of swizzling this calls the real method
		let superview = self.superview
		swizzledRemoveFromSuperview()
		superview?.observers?.allObjects.forEach { $0.didRemoveSubview(self, from: superview!) }
	}
}
#endif
