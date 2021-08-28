//
//  Created on 03/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

open class NavigationControllerWrapper: UIViewController {
	public typealias Configurator<T: UIViewController> = (_ controller: T, _ animated: Bool, _ completion: (() -> Void)?) -> Void

	public struct NavigateBuilderResult<T: UIViewController> {
		public let controller: T
		public let options: Options

		public init(controller: T, options: Options) {
			self.controller = controller
			self.options = options
		}
	}

	public struct Options: ValueWith {
		public var navigationBarVisibility: Visibility
		public var precedingItemNavigationState: PrecedingItemNavigationState
		public var swipeBackGestureState: EnablementState

		public init(
			navigationBar navigationBarVisibility: Visibility,
			precedingItemNavigationState: PrecedingItemNavigationState = .enabled,
			swipeBackGesture swipeBackGestureState: EnablementState = .enabled
		) {
			self.navigationBarVisibility = navigationBarVisibility
			self.precedingItemNavigationState = precedingItemNavigationState
			self.swipeBackGestureState = swipeBackGestureState
		}
	}

	public enum PrecedingItemNavigationState {
		case disabled(attemptClosure: () -> Void = {})
		case enabled
	}

	private struct ControllerOptions: ValueWith {
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

	private(set) lazy var precedingControllerNavigator: PrecedingControllerNavigator = PrecedingControllerNavigatorImplementation(parent: self)
	private let wrappedNavigationController: UINavigationController
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
		controllerOptions.append(.init(
			controller: rootViewController,
			options: .init(
				navigationBar: navigationBarVisibility,
				precedingItemNavigationState: .disabled(),
				swipeBackGesture: .disabled
			)
		))
		super.init(nibName: nil, bundle: nil)
		wrappedNavigationController.delegate = internalDelegate
		wrappedNavigationController.interactivePopGestureRecognizer?.delegate = nil // allows the swipe-from-left-edge back gesture to work
	}

	public override func loadView() {
		super.loadView()

		addChild(wrappedNavigationController)
		view.addSubview(wrappedNavigationController.view)
		wrappedNavigationController.view.edgesToSuperview().activate()
		wrappedNavigationController.didMove(toParent: self)
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	public func navigateToRootViewController<T: UIViewController>(configurator: Configurator<T>? = nil, animated: Bool, completion: (() -> Void)? = nil) {
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

	public func navigateToExistingOrNewViewController<T: UIViewController>(_ controller: T, configurator: Configurator<T>? = nil, factory: (_ precedingControllerNavigator: PrecedingControllerNavigator) -> NavigateBuilderResult<T>, animated: Bool, completion: (() -> Void)? = nil) {
		navigateToExistingOrNewViewController(where: { $0 == controller }, configurator: configurator, factory: factory, animated: animated, completion: completion)
	}

	public func navigateToExistingOrNewViewController<T: UIViewController>(where predicate: (T) -> Bool = { _ in true }, configurator: Configurator<T>? = nil, factory: (_ precedingControllerNavigator: PrecedingControllerNavigator) -> NavigateBuilderResult<T>, animated: Bool, completion: (() -> Void)? = nil) {
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
		controllerOptions.append(.init(controller: viewController, options: options))
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
		updateOptions(animated: animated)
	}

	private func setNeedsDelegatedChildViewControllerUpdates() {
		setNeedsStatusBarAppearanceUpdate()
		setNeedsUpdateOfHomeIndicatorAutoHidden()
		setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
	}

	private func updateOptions(animated: Bool) {
		guard let topViewController = topViewController else { return }
		updateOptions(for: topViewController, animated: animated)
	}

	private func updateOptions(for viewController: UIViewController, animated: Bool) {
		let options = options(for: viewController)
		wrappedNavigationController.setNavigationBarHidden(options.navigationBarVisibility == .hidden, animated: animated)
		if wrappedNavigationController.interactivePopGestureRecognizer?.state == .possible {
			wrappedNavigationController.interactivePopGestureRecognizer?.isEnabled = options.swipeBackGestureState.isEnabled
		}
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
			guard let targetControllerIndex = parent.wrappedNavigationController.viewControllers.firstIndex(where: { $0.navigationItem == navigationItem }) else { fatalError("View controller owning navigation item \(navigationItem) is not on the stack") }

			var currentIndex = parent.wrappedNavigationController.viewControllers.count - 1
			while currentIndex > targetControllerIndex {
				let controller = parent.wrappedNavigationController.viewControllers[currentIndex]
				switch parent.options(for: controller).precedingItemNavigationState {
				case let .disabled(attemptClosure):
					attemptClosure()
					return
				case .enabled:
					break
				}
				currentIndex -= 1
			}

			let targetController = parent.wrappedNavigationController.viewControllers[targetControllerIndex]
			parent.popToViewController(targetController, animated: animated, completion: completion)
		}
	}

	private class InternalDelegate: NSObject, UINavigationControllerDelegate {
		private unowned let parent: NavigationControllerWrapper

		init(parent: NavigationControllerWrapper) {
			self.parent = parent
		}

		func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
			parent.updateOptions(for: viewController, animated: animated)

			parent.targetOrCurrentViewController = viewController
			parent.setNeedsDelegatedChildViewControllerUpdates()
		}

		func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
			let shouldEnableSwipeBackGesture: Bool
			if navigationController.viewControllers.first == viewController {
				shouldEnableSwipeBackGesture = false
				navigationController.interactivePopGestureRecognizer?.isEnabled = false
			} else {
				shouldEnableSwipeBackGesture = parent.options(for: viewController).swipeBackGestureState.isEnabled
			}
			parent.wrappedNavigationController.interactivePopGestureRecognizer?.isEnabled = shouldEnableSwipeBackGesture

			parent.targetOrCurrentViewController = viewController
			parent.setNeedsDelegatedChildViewControllerUpdates()
		}
	}
}
#endif
