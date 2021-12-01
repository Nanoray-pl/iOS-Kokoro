//
//  Created on 11/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUI
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	private lazy var mainRouter: Router & MainRoute = MainWindowRouter(window: window!)

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		let window = UIWindow()
		self.window = window
		mainRouter.showMain()
		window.makeKeyAndVisible()

		return true
	}
}
