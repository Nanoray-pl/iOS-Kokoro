//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import UIKit

open class NavigationControllerWrapper: UIViewController {
	public struct NavigateBuilderResult<T: UIViewController> {
		public let controller: T
		public let options: Options

		public init(controller: T, options: Options) {
			self.controller = controller
			self.options = options
		}
	}

	public struct Options: Hashable {
		public let navigationBarVisibility: Visibility
		public let swipeBackGestureState: EnablementState

		public init(navigationBar navigationBarVisibility: Visibility, swipeBackGesture swipeBackGestureState: EnablementState = .enabled) {
			self.navigationBarVisibility = navigationBarVisibility
			self.swipeBackGestureState = swipeBackGestureState
		}
	}

	private(set) lazy var precedingControllerNavigator: PrecedingControllerNavigator = PrecedingControllerNavigatorImplementation(parent: self)
	private let wrappedNavigationController: UINavigationController
	private let hiddenNavigationBarControllers = NSHashTable<UIViewController>(options: .weakMemory)
	private let disabledSwipeBackGestureControllers = NSHashTable<UIViewController>(options: .weakMemory)
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
		return navigationBar.isHidden ? (targetOrCurrentViewController ?? super.childForStatusBarHidden) : nil
	}

	open override var childForStatusBarStyle: UIViewController? {
		return navigationBar.isHidden ? (targetOrCurrentViewController ?? super.childForStatusBarStyle) : nil
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

	public var topViewController: UIViewController? {
		return wrappedNavigationController.topViewController
	}

	public var viewControllers: [UIViewController] {
		return wrappedNavigationController.viewControllers
	}

	public var navigationBar: UINavigationBar {
		return wrappedNavigationController.navigationBar
	}

	public init(rootViewController: UIViewController, navigationControllerFactory: (_ rootViewController: UIViewController) -> UINavigationController = { UINavigationController(rootViewController: $0) }, withNavigationBar navigationBarVisibility: Visibility) {
		wrappedNavigationController = navigationControllerFactory(rootViewController)
		if navigationBarVisibility == .hidden {
			hiddenNavigationBarControllers.add(rootViewController)
		}
		super.init(nibName: nil, bundle: nil)
		wrappedNavigationController.delegate = internalDelegate
		wrappedNavigationController.interactivePopGestureRecognizer?.delegate = nil // allows the swipe-from-left-edge back gesture to work
	}

	open override func loadView() {
		super.loadView()

		addChild(wrappedNavigationController)
		view.addSubview(wrappedNavigationController.view)
		wrappedNavigationController.view.edgesToSuperview().activate()
		wrappedNavigationController.didMove(toParent: self)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public func navigateToRootViewController<T: UIViewController>(configurator: ((_ controller: T, _ animated: Bool, _ completion: (() -> Void)?) -> Void)? = nil, animated: Bool, completion: (() -> Void)? = nil) {
		guard let rootController = viewControllers.first as? T else { return }
		if viewControllers.count == 1 {
			if let configurator = configurator {
				configurator(rootController, animated, completion)
			} else {
				completion?()
			}
		} else {
			configurator?(rootController, false, nil)
			popToViewController(rootController, animated: animated, completion: completion)
		}
	}

	public func navigateToExistingOrNewViewController<T: UIViewController>(_ controller: T, configurator: ((_ controller: T, _ animated: Bool, _ completion: (() -> Void)?) -> Void)? = nil, factory: (_ precedingControllerNavigator: PrecedingControllerNavigator) -> NavigateBuilderResult<T>, animated: Bool, completion: (() -> Void)? = nil) {
		navigateToExistingOrNewViewController(where: { $0 == controller }, configurator: configurator, factory: factory, animated: animated, completion: completion)
	}

	public func navigateToExistingOrNewViewController<T: UIViewController>(where predicate: (_ controller: T) -> Bool = { _ in true }, configurator: ((_ controller: T, _ animated: Bool, _ completion: (() -> Void)?) -> Void)? = nil, factory: (_ precedingControllerNavigator: PrecedingControllerNavigator) -> NavigateBuilderResult<T>, animated: Bool, completion: (() -> Void)? = nil) {
		if let existingViewController = topViewController as? T, predicate(existingViewController) {
			if let configurator = configurator {
				configurator(existingViewController, animated, completion)
			} else {
				completion?()
			}
			return
		}

		if let existingViewController = viewControllers.compactMap({ $0 as? T }).last(where: predicate) {
			configurator?(existingViewController, false, nil)
			popToViewController(existingViewController, animated: animated, completion: completion)
			return
		}

		let result = factory(precedingControllerNavigator)
		pushViewController(result.controller, options: result.options, animated: animated, completion: completion)
	}

	public func pushViewController(_ viewController: UIViewController, options: Options, animated: Bool, completion: (() -> Void)? = nil) {
		if options.navigationBarVisibility == .hidden {
			hiddenNavigationBarControllers.add(viewController)
		}
		if options.swipeBackGestureState == .disabled {
			disabledSwipeBackGestureControllers.add(viewController)
		}
		wrappedNavigationController.pushViewController(viewController, animated: animated, completion: completion)
	}

	@discardableResult
	public func popViewController(animated: Bool, completion: (() -> Void)? = nil) -> UIViewController? {
		return wrappedNavigationController.popViewController(animated: animated, completion: completion)
	}

	@discardableResult
	public func popToViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
		return wrappedNavigationController.popToViewController(viewController, animated: animated, completion: completion)
	}

	@discardableResult
	public func popToRootViewController(animated: Bool, completion: (() -> Void)? = nil) -> [UIViewController]? {
		return wrappedNavigationController.popToRootViewController(animated: animated, completion: completion)
	}

	private func updateDelegatedChildViewControllers() {
		setNeedsStatusBarAppearanceUpdate()
		setNeedsUpdateOfHomeIndicatorAutoHidden()
		setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
	}

	private class PrecedingControllerNavigatorImplementation: PrecedingControllerNavigator {
		private unowned let parent: NavigationControllerWrapper

		init(parent: NavigationControllerWrapper) {
			self.parent = parent
		}

		func precedingNavigationItems(for controller: UIViewController) -> [UINavigationItem] {
			guard let index = parent.wrappedNavigationController.viewControllers.firstIndex(of: controller) else { return [] }
			return parent.wrappedNavigationController.viewControllers.prefix(index).map(\.navigationItem)
		}

		func navigateBackToViewController(owning navigationItem: UINavigationItem, animated: Bool, completion: (() -> Void)?) {
			guard let controller = parent.wrappedNavigationController.viewControllers.first(where: { $0.navigationItem == navigationItem }) else { fatalError("View controller owning navigation item \(navigationItem) is not on the stack") }
			parent.popToViewController(controller, animated: animated, completion: completion)
		}
	}

	private func willShow(_ controller: UIViewController, animated: Bool, in navigationController: UINavigationController) {
		let shouldHide = hiddenNavigationBarControllers.contains(controller)
		navigationController.setNavigationBarHidden(shouldHide, animated: animated)

		let shouldDisableSwipeBackGesture = disabledSwipeBackGestureControllers.contains(controller)
		navigationController.interactivePopGestureRecognizer?.isEnabled = !shouldDisableSwipeBackGesture

		targetOrCurrentViewController = controller
		updateDelegatedChildViewControllers()
	}

	private func didShow(_ controller: UIViewController, animated: Bool, in navigationController: UINavigationController) {
		if navigationController.viewControllers.first == controller {
			navigationController.interactivePopGestureRecognizer?.isEnabled = false
		}

		targetOrCurrentViewController = controller
		updateDelegatedChildViewControllers()
	}

	private class InternalDelegate: NSObject, UINavigationControllerDelegate {
		private unowned let parent: NavigationControllerWrapper

		init(parent: NavigationControllerWrapper) {
			self.parent = parent
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
