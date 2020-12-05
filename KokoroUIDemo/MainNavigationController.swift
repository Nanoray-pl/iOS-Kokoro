//
//  Created on 11/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUI
import UIKit

class MainNavigationController: NavigationControllerWrapper {
	init() {
		let root = MenuViewController()
		super.init(rootViewController: root, withNavigationBar: .visible)
		root.router = self
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension MainNavigationController: ProportionalOffsetConstraintRoute, ProgressBarsRoute, FlexColumnCollectionViewLayoutRoute {
	func showProportionalOffsetConstraint(animated: Bool) {
		navigateToExistingOrNewViewController(
			factory: { _ in .init(controller: ProportionalOffsetConstraintViewController(), options: .init(navigationBar: .visible)) },
			animated: animated
		)
	}

	func showFlexColumnCollectionViewLayout(animated: Bool) {
		navigateToExistingOrNewViewController(
			factory: { _ in .init(controller: FlexColumnCollectionViewLayoutViewController(), options: .init(navigationBar: .visible)) },
			animated: animated
		)
	}

	func showProgressBars(animated: Bool) {
		navigateToExistingOrNewViewController(
			factory: { _ in .init(controller: ProgressBarsViewController(), options: .init(navigationBar: .visible)) },
			animated: animated
		)
	}
}
