//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

public protocol PrecedingControllerNavigator: AnyObject {
	func precedingNavigationItems(for controller: UIViewController) -> [UINavigationItem]
	func navigateBackToViewController(owning navigationItem: UINavigationItem, animated: Bool, completion: (() -> Void)?)
}

public extension PrecedingControllerNavigator {
	func navigateBackToViewController(owning navigationItem: UINavigationItem, animated: Bool) {
		navigateBackToViewController(owning: navigationItem, animated: animated, completion: nil)
	}

	func menuForPrecedingNavigationItems(for controller: UIViewController) -> ButtonMenuConfigurator.Menu? {
		// back button menus should only be available on iOS 14
		if #available(iOS 14, *) {
			let precedingNavigationItems = self.precedingNavigationItems(for: controller)
			return .init(
				children: precedingNavigationItems.reversed().map { item in
					return ButtonMenuConfigurator.MenuAction(
						title: item.title ?? SystemUILocalizable.back,
						handler: .closure { [weak self] in self?.navigateBackToViewController(owning: item, animated: Animated.motionBased.value) }
					)
				}
			)
		} else {
			return nil
		}
	}
}
#endif
