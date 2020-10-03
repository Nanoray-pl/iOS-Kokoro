//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public extension UIView {
	var isHiddenIncludingSuperviews: Bool {
		var current: UIView? = self
		while let testing = current {
			if testing.isHidden {
				return true
			}
			current = testing.superview
		}
		return false
	}

	func findCommonView(with other: UIView) -> UIView? {
		var current1: UIView? = self
		var current2: UIView? = other
		var views: Set<UIView> = [current1!, current2!]

		while current1 != nil || current2 != nil {
			current1 = current1?.superview
			if let view = current1 {
				if views.contains(view) {
					return view
				}
				views.insert(view)
			}

			current2 = current2?.superview
			if let view = current2 {
				if views.contains(view) {
					return view
				}
				views.insert(view)
			}
		}
		return nil
	}

	// MARK: - All Subviews

	func allSubviews<T: UIView>(ignoreHidden: Bool = false) -> [T] {
		return allSubviews(ignoreHidden: ignoreHidden, where: { _ in true })
	}

	func allSubviews<T: UIView>(ignoreHidden: Bool = false, where predicate: (T) -> Bool) -> [T] {
		if ignoreHidden && isHiddenIncludingSuperviews {
			return []
		}

		return subviews.flatMap { $0.allViewsWithoutCheckingSuperviewHidden(ignoreHidden: ignoreHidden, where: predicate) }
	}

	func allViews<T: UIView>(ignoreHidden: Bool = false) -> [T] {
		return allViews(ignoreHidden: ignoreHidden, where: { _ in true })
	}

	func allViews<T: UIView>(ignoreHidden: Bool = false, where predicate: (T) -> Bool) -> [T] {
		if ignoreHidden && isHiddenIncludingSuperviews {
			return []
		}

		return allViewsWithoutCheckingSuperviewHidden(ignoreHidden: ignoreHidden, where: predicate)
	}

	private func allViewsWithoutCheckingSuperviewHidden<T: UIView>(ignoreHidden: Bool = false, where predicate: (T) -> Bool) -> [T] {
		var results = [T]()

		if ignoreHidden && isHidden {
			return results
		}

		if let typedView = self as? T {
			if predicate(typedView) {
				results.append(typedView)
			}
		}

		subviews.forEach {
			results.append(contentsOf: $0.allViews(ignoreHidden: ignoreHidden, where: predicate))
		}

		return results
	}

	// MARK: - First Subview

	func firstSubview<T: UIView>(ignoreHidden: Bool = false) -> T? {
		return firstSubview(ignoreHidden: ignoreHidden, where: { _ in true })
	}

	func firstSubview<T: UIView>(ignoreHidden: Bool = false, where predicate: (T) -> Bool) -> T? {
		if ignoreHidden && isHiddenIncludingSuperviews {
			return nil
		}

		for subview in subviews {
			if let result = subview.firstViewWithoutCheckingSuperviewHidden(ignoreHidden: ignoreHidden, where: predicate) {
				return result
			}
		}
		return nil
	}

	func firstView<T: UIView>(ignoreHidden: Bool = false) -> T? {
		return firstView(ignoreHidden: ignoreHidden, where: { _ in true })
	}

	func firstView<T: UIView>(ignoreHidden: Bool = false, where predicate: (T) -> Bool) -> T? {
		if ignoreHidden && isHiddenIncludingSuperviews {
			return nil
		}

		return firstViewWithoutCheckingSuperviewHidden(ignoreHidden: ignoreHidden, where: predicate)
	}

	private func firstViewWithoutCheckingSuperviewHidden<T: UIView>(ignoreHidden: Bool = false, where predicate: (T) -> Bool) -> T? {
		if ignoreHidden && isHidden {
			return nil
		}

		if let typedView = self as? T {
			if predicate(typedView) {
				return typedView
			}
		}

		for subview in subviews {
			if let result = subview.firstView(ignoreHidden: ignoreHidden, where: predicate) {
				return result
			}
		}
		return nil
	}

	// MARK: - Contains Subview

	func containsSubview(_ view: UIView) -> Bool {
		return containsSubview(where: { $0 == view })
	}

	func containsSubview<T: UIView>(ignoreHidden: Bool = false, where predicate: (T) -> Bool) -> Bool {
		return firstSubview(ignoreHidden: ignoreHidden, where: predicate) != nil
	}

	func containsView(_ view: UIView) -> Bool {
		return containsView(where: { $0 == view })
	}

	func containsView<T: UIView>(ignoreHidden: Bool = false, where predicate: (T) -> Bool) -> Bool {
		return firstView(ignoreHidden: ignoreHidden, where: predicate) != nil
	}
}
#endif
