//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

open class TabAndNavigationControllerWrapper: UIViewController {
	public struct NavigateBuilderResult<T: UIViewController> {
		public let controller: T
		public let options: Options

		public init(controller: T, options: Options) {
			self.controller = controller
			self.options = options
		}
	}

	public struct Item {
		let controller: UIViewController
		let title: String
		let icon: UIImage?
		let selectedIcon: UIImage?
		let navigationBarVisibility: Visibility

		public init(controller: UIViewController, title: String, icon: UIImage?, selectedIcon: UIImage? = nil, withNavigationBar navigationBarVisibility: Visibility) {
			self.controller = controller
			self.title = title
			self.icon = icon
			self.selectedIcon = selectedIcon
			self.navigationBarVisibility = navigationBarVisibility
		}
	}

	public struct Options: Hashable {
		public let barOptions: [BarOption]
		public let swipeBackGestureState: EnablementState

		public init(barOptions: [BarOption], swipeBackGesture swipeBackGestureState: EnablementState = .enabled) {
			self.barOptions = barOptions
			self.swipeBackGestureState = swipeBackGestureState
		}
	}

	public enum BarOption: Hashable {
		case without(_ bar: Bar)
		case with(_ bar: Bar)

		public enum Bar: Hashable, CaseIterable {
			case navigation, tab
		}
	}

	public enum NavigateScope: Hashable {
		case currentTab, allTabs
	}

	private class NavigationState {
		private(set) weak var navigationController: UINavigationController!
		weak var currentController: UIViewController!
		weak var targetController: UIViewController?

		init(for navigationController: UINavigationController, currentController: UIViewController) {
			self.navigationController = navigationController
			self.currentController = currentController
		}
	}

	private(set) lazy var precedingControllerNavigator: PrecedingControllerNavigator = PrecedingControllerNavigatorImplementation(parent: self)
	private lazy var wrappedTabBarController = UITabBarController().with { $0.delegate = internalDelegate }
	private let hiddenTabBarControllers = NSHashTable<UIViewController>(options: .weakMemory)
	private let hiddenNavigationBarControllers = NSHashTable<UIViewController>(options: .weakMemory)
	private let disabledSwipeBackGestureControllers = NSHashTable<UIViewController>(options: .weakMemory)
	private let navigationState = NSMapTable<UINavigationController, NavigationState>(keyOptions: .weakMemory, valueOptions: .strongMemory)
	private var isCustomModalInPresentationValueSet = false
	private weak var targetOrCurrentViewController: UIViewController?
	private lazy var internalDelegate = InternalDelegate(parent: self) // swiftlint:disable:this weak_delegate

	open override var childForHomeIndicatorAutoHidden: UIViewController? {
		return targetOrCurrentViewController ?? super.childForHomeIndicatorAutoHidden
	}

	open override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
		return targetOrCurrentViewController ?? super.childForScreenEdgesDeferringSystemGestures
	}

	open override var childForStatusBarHidden: UIViewController? {
		return currentNavigationBar.isHidden ? (targetOrCurrentViewController ?? super.childForStatusBarHidden) : nil
	}

	open override var childForStatusBarStyle: UIViewController? {
		return currentNavigationBar.isHidden ? (targetOrCurrentViewController ?? super.childForStatusBarStyle) : nil
	}

	open override var isModalInPresentation: Bool {
		get {
			return isCustomModalInPresentationValueSet ? super.isModalInPresentation : (topViewController?.isModalInPresentation ?? super.isModalInPresentation)
		}
		set {
			super.isModalInPresentation = newValue
			isCustomModalInPresentationValueSet = true
		}
	}

	public var currentNavigationController: UINavigationController {
		get {
			return wrappedTabBarController.selectedViewController as! UINavigationController
		}
		set {
			wrappedTabBarController.selectedViewController = newValue
		}
	}

	public var navigationControllers: [UINavigationController] {
		return (wrappedTabBarController.viewControllers ?? []).ofType(UINavigationController.self)
	}

	public var topViewController: UIViewController? {
		return currentNavigationController.topViewController
	}

	public var currentViewControllers: [UIViewController] {
		return currentNavigationController.viewControllers
	}

	public var currentNavigationBar: UINavigationBar {
		return currentNavigationController.navigationBar
	}

	private var tabBar: UITabBar {
		return wrappedTabBarController.tabBar
	}

	public var isTabBarHidden: Bool {
		return !tabBar.frame.intersects(view.frame)
	}

	private var tabBarAnimator: UIViewPropertyAnimator? {
		willSet {
			tabBarAnimator?.with {
				if $0.state == .active {
					$0.stopAnimation(false)
				}
				if $0.state == .stopped {
					$0.finishAnimation(at: .current)
				}
			}
		}
	}

	public init(items: [Item]) {
		super.init(nibName: nil, bundle: nil)
		setupItems(items)
	}

	public final func setupItems(_ items: [Item]) {
		wrappedTabBarController.setViewControllers(
			items.map {
				Self.createNavigationController(for: $0).with {
					$0.delegate = internalDelegate
				}
			},
			animated: false
		)

		hiddenNavigationBarControllers.removeAllObjects()

		let tabItems = tabBar.items!
		for index in 0 ..< items.count {
			let item = items[index]
			if item.navigationBarVisibility == .hidden {
				hiddenNavigationBarControllers.add(item.controller)
			}
			setupTabItem(tabItems[index], for: item)
		}
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private static func createNavigationController(for item: Item) -> UINavigationController {
		return UINavigationController(rootViewController: item.controller).with {
			$0.interactivePopGestureRecognizer?.delegate = nil // allows the swipe-from-left-edge back gesture to work
		}
	}

	private func setupTabItem(_ tabItem: UITabBarItem, for item: Item) {
		tabItem.title = item.title
		tabItem.image = item.icon
		tabItem.selectedImage = item.selectedIcon
	}

	open override func loadView() {
		super.loadView()

		addChild(wrappedTabBarController)
		view.addSubview(wrappedTabBarController.view)
		wrappedTabBarController.view.edgesToSuperview().activate()
		wrappedTabBarController.didMove(toParent: self)
	}

	private func navigationControllers(for navigateScope: NavigateScope) -> [UINavigationController] {
		switch navigateScope {
		case .currentTab:
			return [currentNavigationController]
		case .allTabs:
			var result = navigationControllers
			result.remove(at: result.firstIndex(of: currentNavigationController)!)
			result.insert(currentNavigationController, at: 0)
			return result
		}
	}

	public func navigateToRootViewController<T: UIViewController>(type: T.Type = T.self, configurator: (_ controller: T, _ animated: Bool, _ completion: (() -> Void)?) -> Void = { _, _, completion in completion?() }, animated: Bool, completion: (() -> Void)? = nil) {
		for navigationController in navigationControllers(for: .allTabs) {
			guard let rootController = navigationController.viewControllers.first as? T else { continue }
			if navigationController.viewControllers.count == 1 {
				configurator(rootController, animated, completion)
				break
			} else {
				configurator(rootController, false, nil)
				navigationController.popToViewController(rootController, animated: animated, completion: completion)
				break
			}
		}
	}

	public func navigateToExistingOrNewViewController<T: UIViewController>(_ controller: T, configurator: (_ controller: T, _ animated: Bool, _ completion: (() -> Void)?) -> Void = { _, _, completion in completion?() }, factory: (_ precedingControllerNavigator: PrecedingControllerNavigator) -> NavigateBuilderResult<T>, inScope navigateScope: NavigateScope = .currentTab, animated: Bool, completion: (() -> Void)? = nil) {
		navigateToExistingOrNewViewController(where: { $0 == controller }, configurator: configurator, factory: factory, animated: animated, completion: completion)
	}

	public func navigateToExistingOrNewViewController<T: UIViewController>(where predicate: (T) -> Bool = { _ in true }, configurator: (_ controller: T, _ animated: Bool, _ completion: (() -> Void)?) -> Void = { _, _, completion in completion?() }, factory: (_ precedingControllerNavigator: PrecedingControllerNavigator) -> NavigateBuilderResult<T>, inScope navigateScope: NavigateScope = .currentTab, animated: Bool, completion: (() -> Void)? = nil) {
		if let existingViewController = topViewController as? T, predicate(existingViewController) {
			configurator(existingViewController, animated, completion)
			return
		}

		for navigationController in navigationControllers(for: navigateScope) {
			if let existingViewController = navigationController.viewControllers.compactMap({ $0 as? T }).last(where: predicate) {
				configurator(existingViewController, false, nil)
				if navigationController == currentNavigationController {
					navigationController.popToViewController(existingViewController, animated: animated, completion: completion)
				} else {
					navigationController.popToViewController(existingViewController, animated: false)
					currentNavigationController = navigationController
					completion?()
				}
				return
			}
		}

		let result = factory(precedingControllerNavigator)
		pushViewController(result.controller, options: result.options, animated: animated, completion: completion)
	}

	public func pushViewController(_ viewController: UIViewController, options: Options, animated: Bool, completion: (() -> Void)? = nil) {
		let barShouldHideMap = BarOption.Bar.allCases.reduce([BarOption.Bar: Bool]()) { result, bar in
			var result = result
			switch bar {
			case .navigation:
				result[bar] = hiddenNavigationBarControllers.contains(topViewController)
			case .tab:
				result[bar] = hiddenTabBarControllers.contains(topViewController)
			}

			options.barOptions.forEach {
				switch $0 {
				case .without(bar):
					result[bar] = true
				case .with(bar):
					result[bar] = false
				case .without, .with:
					break
				}
			}
			return result
		}

		if barShouldHideMap[.navigation]! {
			hiddenNavigationBarControllers.add(viewController)
		}
		if barShouldHideMap[.tab]! {
			hiddenTabBarControllers.add(viewController)
		}
		if !options.swipeBackGestureState.isEnabled {
			disabledSwipeBackGestureControllers.add(viewController)
		}
		currentNavigationController.pushViewController(viewController, animated: animated, completion: completion)
	}

	@discardableResult
	public func popViewController(animated: Bool, completion: (() -> Void)? = nil) -> UIViewController? {
		return currentNavigationController.popViewController(animated: animated, completion: completion)
	}

	@discardableResult
	public func popToViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
		return currentNavigationController.popToViewController(viewController, animated: animated, completion: completion)
	}

	@discardableResult
	public func popToRootViewController(animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
		return currentNavigationController.popToRootViewController(animated: animated, completion: completion)
	}

	private func setTabBarHidden(_ isHidden: Bool, animated: Bool, completion: (() -> Void)? = nil) {
		guard isTabBarHidden != isHidden else { return }
		tabBarAnimator = nil

		let offsetY = tabBar.frame.height * (isHidden ? 1 : -1)
		let endFrame = CGRect(origin: .init(x: 0, y: view.frame.height - tabBar.frame.height * (isHidden ? 0 : 1)), size: tabBar.frame.size)
		let originalInsets = currentNavigationController.additionalSafeAreaInsets
		let newInsets = UIEdgeInsets(top: originalInsets.top, left: originalInsets.left, bottom: originalInsets.bottom - offsetY, right: originalInsets.right)

		if isHidden {
			currentNavigationController.additionalSafeAreaInsets = newInsets
			currentNavigationController.view.setNeedsLayout()
		}

		tabBarAnimator = Animated(booleanLiteral: animated).run(
			animations: {
				self.tabBar.frame = endFrame
			},
			completion: { [weak currentNavigationController] in
				if !isHidden, let currentNavigationController = currentNavigationController {
					currentNavigationController.additionalSafeAreaInsets = newInsets
					currentNavigationController.view.setNeedsLayout()
				}
				completion?()
			}
		)
	}

	private func navigationState(for navigationController: UINavigationController) -> NavigationState {
		if let navigationState = self.navigationState.object(forKey: navigationController) {
			return navigationState
		} else {
			let navigationState = NavigationState(for: navigationController, currentController: navigationController.topViewController!)
			self.navigationState.setObject(navigationState, forKey: navigationController)
			return navigationState
		}
	}

	open func didSelectViewController(_ controller: UIViewController) {
		targetOrCurrentViewController = topViewController
		updateDelegatedChildViewControllers()
	}

	private func updateDelegatedChildViewControllers() {
		setNeedsStatusBarAppearanceUpdate()
		setNeedsUpdateOfHomeIndicatorAutoHidden()
		setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
	}

	private class PrecedingControllerNavigatorImplementation: PrecedingControllerNavigator {
		private unowned let parent: TabAndNavigationControllerWrapper

		init(parent: TabAndNavigationControllerWrapper) {
			self.parent = parent
		}

		func precedingNavigationItems(for controller: UIViewController) -> [UINavigationItem] {
			guard let navigationController = parent.navigationControllers.first(where: { $0.viewControllers.contains(controller) }) else { return [] }
			guard let index = navigationController.viewControllers.firstIndex(of: controller) else { return [] }
			return navigationController.viewControllers.prefix(index).map(\.navigationItem)
		}

		func navigateBackToViewController(owning navigationItem: UINavigationItem, animated: Bool, completion: (() -> Void)?) {
			guard let controller = parent.navigationControllers.flatMap(\.viewControllers).first(where: { $0.navigationItem == navigationItem }) else { fatalError("View controller owning navigation item \(navigationItem) is not on the stack") }
			parent.popToViewController(controller, animated: animated, completion: completion)
		}
	}

	private func setupBarVisibility(for navigationState: NavigationState, setupNavigationBar: Bool = true, animated: Bool) {
		let controller = navigationState.targetController ?? navigationState.currentController!
		let isNavigationBarHidden = hiddenNavigationBarControllers.contains(controller)
		let isTabBarHidden = hiddenTabBarControllers.contains(controller)
		let isSwipeBackGestureDisabled = (navigationState.navigationController.viewControllers.first == navigationState.currentController || disabledSwipeBackGestureControllers.contains(controller))

		if setupNavigationBar {
			navigationState.navigationController.setNavigationBarHidden(isNavigationBarHidden, animated: animated)
		}
		setTabBarHidden(isTabBarHidden, animated: animated)
		navigationState.navigationController.interactivePopGestureRecognizer?.isEnabled = !isSwipeBackGestureDisabled
	}

	private func willShow(_ controller: UIViewController, animated: Bool, in navigationController: UINavigationController) {
		let navigationState = self.navigationState(for: navigationController)
		navigationState.targetController = controller
		setupBarVisibility(for: navigationState, animated: animated)

		targetOrCurrentViewController = controller
		updateDelegatedChildViewControllers()

		navigationController.topViewController?.transitionCoordinator?.notifyWhenInteractionChanges { [weak self] context in
			if context.isCancelled {
				self?.targetOrCurrentViewController = navigationState.currentController
				self?.updateDelegatedChildViewControllers()

				navigationState.targetController = nil
				self?.setupBarVisibility(for: navigationState, setupNavigationBar: false, animated: Animated.motionBased.value)
			}
		}
	}

	private func didShow(_ controller: UIViewController, animated: Bool, in navigationController: UINavigationController) {
		let navigationState = self.navigationState(for: navigationController)
		navigationState.currentController = controller
		navigationState.targetController = nil
		setupBarVisibility(for: navigationState, animated: false)

		targetOrCurrentViewController = controller
		updateDelegatedChildViewControllers()
	}

	private class InternalDelegate: NSObject, UITabBarControllerDelegate, UINavigationControllerDelegate {
		private unowned let parent: TabAndNavigationControllerWrapper

		init(parent: TabAndNavigationControllerWrapper) {
			self.parent = parent
		}

		func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
			guard let navigationController = viewController as? UINavigationController else { return }
			if let controller = navigationController.viewControllers.last {
				parent.didSelectViewController(controller)
			}
		}

		func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
			parent.willShow(viewController, animated: animated, in: navigationController)
		}

		func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
			parent.didShow(viewController, animated: animated, in: navigationController)
		}
	}
}
#endif
