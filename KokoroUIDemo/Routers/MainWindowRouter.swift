//
//  Created on 01/12/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUI
import KokoroUtils
import UIKit

class MainWindowRouter: Router, ObjectWith {
	let parentRouter: Router? = nil
	var childRouters = [Router]()
	private let window: UIWindow

	private lazy var navigationController = NavigationControllerWrapper(
		rootViewController: MenuViewController(router: self),
		withNavigationBar: .visible
	)

	init(window: UIWindow) {
		self.window = window
	}
}

extension MainWindowRouter: MainRoute {
	func showMain() {
		window.rootViewController = navigationController
	}
}

extension MainWindowRouter: ProportionalOffsetConstraintRoute, ProgressBarsRoute, FlexColumnCollectionViewLayoutRoute, CardDeckViewRoute {
	func showProportionalOffsetConstraint(animated: Bool) {
		navigationController.navigateToExistingOrNewViewController(
			factory: { _ in .init(controller: ProportionalOffsetConstraintViewController(), options: .init(navigationBar: .visible)) },
			animated: animated
		)
	}

	func showFlexColumnCollectionViewLayout(animated: Bool) {
		navigationController.navigateToExistingOrNewViewController(
			factory: { _ in .init(controller: FlexColumnCollectionViewLayoutViewController(), options: .init(navigationBar: .visible)) },
			animated: animated
		)
	}

	func showCardDeckView(animated: Bool) {
		navigationController.navigateToExistingOrNewViewController(
			factory: { _ in .init(controller: CardDeckViewController(), options: .init(navigationBar: .visible)) },
			animated: animated
		)
	}

	func showProgressBars(animated: Bool) {
		navigationController.navigateToExistingOrNewViewController(
			factory: { _ in .init(controller: ProgressBarsViewController(), options: .init(navigationBar: .visible)) },
			animated: animated
		)
	}
}
