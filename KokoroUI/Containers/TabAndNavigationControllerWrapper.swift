//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

open class TabAndNavigationControllerWrapper: UIViewController {
	public typealias Configurator<T: UIViewController> = (_ controller: T, _ animated: Bool, _ completion: (() -> Void)?) -> Void

	public struct NavigateBuilderResult<T: UIViewController> {
		public let controller: T
		public let options: Options

		public init(controller: T, options: Options) {
			self.controller = controller
			self.options = options
		}
	}

	public struct TabBarVisuals {
		public var title: String
		public var icon: UIImage?
		public var selectedIcon: UIImage?
		public var accessibilityIdentifier: String?

		public init(
			title: String,
			icon: UIImage?,
			selectedIcon: UIImage? = nil,
			accessibilityIdentifier: String? = nil
		) {
			self.title = title
			self.icon = icon
			self.selectedIcon = selectedIcon
			self.accessibilityIdentifier = accessibilityIdentifier
		}
	}

	public struct Item {
		public let controller: UIViewController
		public let tabBarVisuals: TabBarVisuals
		public let navigationBarVisibility: Visibility

		public init(controller: UIViewController, tabBarVisuals: TabBarVisuals, withNavigationBar navigationBarVisibility: Visibility) {
			self.controller = controller
			self.tabBarVisuals = tabBarVisuals
			self.navigationBarVisibility = navigationBarVisibility
		}
	}

	public enum PrecedingItemNavigationState {
		case disabled(attemptClosure: () -> Void = {})
		case enabled
	}

	public struct Options: ValueWith {
		public var barDifference: SetDifference<Bar>
		public var precedingItemNavigationState: PrecedingItemNavigationState
		public var swipeBackGestureState: EnablementState

		public init(
			barDifference: SetDifference<Bar>,
			precedingItemNavigationState: PrecedingItemNavigationState = .enabled,
			swipeBackGesture swipeBackGestureState: EnablementState = .enabled
		) {
			self.barDifference = barDifference
			self.precedingItemNavigationState = precedingItemNavigationState
			self.swipeBackGestureState = swipeBackGestureState
		}
	}

	public enum Bar: Hashable, CaseIterable {
		case navigation, tab
	}

	public enum NavigateScope: Hashable {
		case currentTab, allTabs
	}

	private struct ControllerOptions {
		private(set) weak var controller: UIViewController?
		var options: Options

		init(
			controller: UIViewController,
			options: Options
		) {
			self.controller = controller
			self.options = options
		}
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
	private let navigationState = NSMapTable<UINavigationController, NavigationState>(keyOptions: .weakMemory, valueOptions: .strongMemory)
	private var isCustomModalInPresentationValueSet = false
	private weak var targetOrCurrentViewController: UIViewController?
	private lazy var internalDelegate = InternalDelegate(parent: self) // swiftlint:disable:this weak_delegate

	private var controllerOptions = [ControllerOptions]() {
		didSet {
			guard controllerOptions.contains(where: { $0.controller == nil }) else { return }
			controllerOptions = controllerOptions.filter { $0.controller != nil }
		}
	}

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

	@Proxy(\.wrappedTabBarController.selectedViewController, get: { $0 as! UINavigationController }, set: { $0 })
	public var currentNavigationController: UINavigationController

	public var navigationControllers: [UINavigationController] {
		return (wrappedTabBarController.viewControllers ?? []).compactMap { $0 as? UINavigationController }
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

		controllerOptions.removeAll()

		let tabItems = tabBar.items!
		for index in 0 ..< items.count {
			let item = items[index]
			controllerOptions.append(.init(
				controller: item.controller,
				options: .init(
					barDifference: .init().with {
						switch item.navigationBarVisibility {
						case .visible:
							$0.insert(.navigation)
						case .hidden:
							$0.remove(.navigation)
						}
						$0.insert(.tab)
					},
					swipeBackGesture: .disabled
				)
			))
			setupTabItem(tabItems[index], with: item.tabBarVisuals)
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

	private func setupTabItem(_ tabItem: UITabBarItem, with visuals: TabBarVisuals) {
		tabItem.title = visuals.title
		tabItem.image = visuals.icon
		tabItem.selectedImage = visuals.selectedIcon
		tabItem.accessibilityIdentifier = visuals.accessibilityIdentifier
	}

	public override func loadView() {
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

	public func setTabBarVisuals(_ visuals: TabBarVisuals, for navigationController: UINavigationController) {
		guard let index = navigationControllers.firstIndex(of: navigationController) else { fatalError("Navigation controller \(navigationController) is not managed by this TabAndNavigationControllerWrapper.") }
		setupTabItem(tabBar.items![index], with: visuals)
	}

	public func navigateToRootViewController<T: UIViewController>(type: T.Type = T.self, configurator: Configurator<T> = { _, _, completion in completion?() }, animated: Bool, completion: (() -> Void)? = nil) {
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

	public func navigateToExistingOrNewViewController<T: UIViewController>(_ controller: T, configurator: Configurator<T> = { _, _, completion in completion?() }, factory: (_ precedingControllerNavigator: PrecedingControllerNavigator) -> NavigateBuilderResult<T>, inScope navigateScope: NavigateScope = .currentTab, animated: Bool, completion: (() -> Void)? = nil) {
		navigateToExistingOrNewViewController(where: { $0 == controller }, configurator: configurator, factory: factory, animated: animated, completion: completion)
	}

	public func navigateToExistingOrNewViewController<T: UIViewController>(where predicate: (T) -> Bool = { _ in true }, configurator: Configurator<T> = { _, _, completion in completion?() }, factory: (_ precedingControllerNavigator: PrecedingControllerNavigator) -> NavigateBuilderResult<T>, inScope navigateScope: NavigateScope = .currentTab, animated: Bool, completion: (() -> Void)? = nil) {
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
		controllerOptions.append(.init(controller: viewController, options: options))
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

	private func controllerOptions(for viewController: UIViewController) -> ControllerOptions {
		guard let entry = controllerOptions.first(where: { $0.controller == viewController }) else { fatalError("View controller \(viewController) is not on the stack.") }
		return entry
	}

	public func options(for viewController: UIViewController) -> Options {
		return controllerOptions(for: viewController).options
	}

	public func setOptions(to optionsOverride: Options, for viewController: UIViewController, animated: Bool) {
		guard let index = controllerOptions.firstIndex(where: { $0.controller == viewController }) else { fatalError("View controller \(viewController) is not on the stack.") }
		controllerOptions[index].options = optionsOverride
		updateOptionsForAllNavigationControllers(animated: animated)
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

		tabBarAnimator = Animated(booleanLiteral: animated).run(animations: {
			self.tabBar.frame = endFrame
		}, completion: { [weak currentNavigationController] in
			if !isHidden, let currentNavigationController = currentNavigationController {
				currentNavigationController.additionalSafeAreaInsets = newInsets
				currentNavigationController.view.setNeedsLayout()
			}
			completion?()
		})
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

	func didSelectViewController(_ controller: UIViewController) {
		targetOrCurrentViewController = topViewController
		setNeedsDelegatedChildViewControllerUpdates()
	}

	private func setupBarVisibility(for navigationState: NavigationState, setupNavigationBar: Bool = true, animated: Bool) {
		let controller = navigationState.targetController ?? navigationState.currentController!

		var visibleBars = Set(Bar.allCases)
		var allControllers = navigationState.navigationController.viewControllers
		if let targetController = navigationState.targetController, !allControllers.contains(targetController) {
			allControllers.append(targetController)
		}
		for stackController in allControllers {
			visibleBars.apply(options(for: stackController).barDifference)
			if stackController == navigationState.targetController { break }
		}

		if setupNavigationBar {
			navigationState.navigationController.setNavigationBarHidden(!visibleBars.contains(.navigation), animated: animated)
		}
		setTabBarHidden(!visibleBars.contains(.tab), animated: animated)
		if navigationState.navigationController.interactivePopGestureRecognizer?.state == .possible {
			navigationState.navigationController.interactivePopGestureRecognizer?.isEnabled = options(for: controller).swipeBackGestureState == .enabled
		}
	}

	private func setNeedsDelegatedChildViewControllerUpdates() {
		setNeedsStatusBarAppearanceUpdate()
		setNeedsUpdateOfHomeIndicatorAutoHidden()
		setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
	}

	private func updateOptionsForAllNavigationControllers(animated: Bool) {
		navigationControllers.forEach {
			setupBarVisibility(for: navigationState(for: $0), animated: animated)
		}
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
			guard let navigationController = parent.navigationControllers.first(where: { $0.viewControllers.contains { $0.navigationItem == navigationItem } }) else { fatalError("View controller owning navigation item \(navigationItem) is not on the stack") }
			guard let targetControllerIndex = navigationController.viewControllers.firstIndex(where: { $0.navigationItem == navigationItem }) else { fatalError("View controller owning navigation item \(navigationItem) is not on the stack") }

			var currentIndex = navigationController.viewControllers.count - 1
			while currentIndex > targetControllerIndex {
				let controller = navigationController.viewControllers[currentIndex]
				switch parent.options(for: controller).precedingItemNavigationState {
				case let .disabled(attemptClosure):
					attemptClosure()
					return
				case .enabled:
					break
				}
				currentIndex -= 1
			}

			let targetController = navigationController.viewControllers[targetControllerIndex]
			parent.popToViewController(targetController, animated: animated, completion: completion)
		}
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
			let navigationState = parent.navigationState(for: navigationController)
			navigationState.targetController = viewController
			parent.setupBarVisibility(for: navigationState, animated: animated)

			parent.targetOrCurrentViewController = viewController
			parent.setNeedsDelegatedChildViewControllerUpdates()

			navigationController.topViewController?.transitionCoordinator?.notifyWhenInteractionChanges { [weak parent] context in
				if context.isCancelled {
					parent?.targetOrCurrentViewController = navigationState.currentController
					parent?.setNeedsDelegatedChildViewControllerUpdates()

					navigationState.targetController = nil
					parent?.setupBarVisibility(for: navigationState, setupNavigationBar: false, animated: Animated.motionBased.value)
				}
			}
		}

		func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
			let navigationState = parent.navigationState(for: navigationController)
			navigationState.currentController = viewController
			navigationState.targetController = nil
			parent.setupBarVisibility(for: navigationState, animated: false)

			parent.targetOrCurrentViewController = viewController
			parent.setNeedsDelegatedChildViewControllerUpdates()
		}
	}
}
#endif
