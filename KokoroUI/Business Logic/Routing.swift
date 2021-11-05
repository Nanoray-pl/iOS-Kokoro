//
//  Created on 13/02/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public enum RoutingDirection {
	/// Route via the first known upstream (parent) router. Best used if context is known (simple navigation) - for example with navigation controllers.
	case upstream

	/// Route via the last known downstream (child) router. Best used if context is unknown and the base router is near the top of the view hierarchy - for example for modal alerts, with `UIApplication` as the base router.
	case downstream

	/// Try routing `.downstream` first, and if that fails, `.upstream`. Best used if the base router is of unknown origin.
	case anyDirection
}

public protocol RouterAware: AnyObject {
	func optionalRouter<RouteType: Route>(_ direction: RoutingDirection, for routeType: RouteType.Type) -> RouteType?

	/// - Warning: This method will call `fatalError` if it cannot find the specific router.
	func router<RouteType: Route>(_ direction: RoutingDirection, for routeType: RouteType.Type) -> RouteType

	/// - Warning: This method will call `fatalError` if it cannot find the specific router.
	func route<RouteType: Route>(_ direction: RoutingDirection, via routeType: RouteType.Type, routing: (RouteType) -> Void)
}

public extension RouterAware {
	func optionalRouter<RouteType: Route>(for routeType: RouteType.Type) -> RouteType? {
		return optionalRouter(.anyDirection, for: routeType)
	}

	/// - Warning: This method will call `fatalError` if it cannot find the specific router.
	func router<RouteType: Route>(for routeType: RouteType.Type) -> RouteType {
		return router(.anyDirection, for: routeType)
	}

	/// - Warning: This method will call `fatalError` if it cannot find the specific router.
	func route<RouteType: Route>(via routeType: RouteType.Type, routing: (RouteType) -> Void) {
		return route(.anyDirection, via: routeType, routing: routing)
	}
}

public protocol FirstRouterAware: RouterAware {
	/// Returns the first `Router` found in the chain. Best used in simple navigation (when you are sure the router still exists, for example with direct touch handlers).
	var firstRouter: Router? { get }
}

public extension FirstRouterAware {
	/// Returns the root `Router` of this router chain, as in the one with no parent. Best used in complex navigation (when you are not sure `firstRouter` would still exist, for example after receiving a HTTP response).
	var rootRouter: Router? {
		guard var current: Router = firstRouter else { return nil }
		while true {
			if let next = current.parentRouter {
				current = next
			} else {
				break
			}
		}
		return current
	}

	func optionalRouter<RouteType: Route>(_ direction: RoutingDirection, for routeType: RouteType.Type) -> RouteType? {
		return firstRouter?.optionalRouter(direction, for: routeType)
	}

	func router<RouteType: Route>(_ direction: RoutingDirection, for routeType: RouteType.Type) -> RouteType {
		guard let firstRouter = firstRouter else { fatalError("\(self) does not have a `Router` in its chain.") }
		return firstRouter.router(direction, for: routeType)
	}

	func route<RouteType: Route>(_ direction: RoutingDirection, via routeType: RouteType.Type, routing: (RouteType) -> Void) {
		guard let firstRouter = firstRouter else { fatalError("\(self) does not have a `Router` in its chain.") }
		firstRouter.route(direction, via: routeType, routing: routing)
	}
}

public protocol Router: FirstRouterAware {
	var parentRouter: Router? { get }
	var childRouters: [Router] { get }
}

public extension Router {
	var firstRouter: Router? {
		return self
	}

	private func firstUpstreamRouter<RouteType: Route>(for routeType: RouteType.Type) -> RouteType? {
		return (self as? RouteType) ?? parentRouter?.firstUpstreamRouter(for: routeType)
	}

	private func lastDownstreamRouter<RouteType: Route>(for routeType: RouteType.Type) -> RouteType? {
		for childRouter in childRouters.reversed() {
			if let childRouter = childRouter.lastDownstreamRouter(for: routeType) {
				return childRouter
			}
		}
		if let self = self as? RouteType {
			return self
		}
		return nil
	}

	func optionalRouter<RouteType: Route>(_ direction: RoutingDirection, for routeType: RouteType.Type) -> RouteType? {
		let optionalRouter: RouteType?
		switch direction {
		case .upstream:
			optionalRouter = firstUpstreamRouter(for: routeType)
		case .downstream:
			optionalRouter = lastDownstreamRouter(for: routeType)
		case .anyDirection:
			optionalRouter = lastDownstreamRouter(for: routeType) ?? firstUpstreamRouter(for: routeType)
		}
		return optionalRouter
	}

	func router<RouteType: Route>(_ direction: RoutingDirection, for routeType: RouteType.Type) -> RouteType {
		guard let router = optionalRouter(direction, for: routeType) else { fatalError("No known router handling \(routeType).") }
		return router
	}

	func route<RouteType: Route>(_ direction: RoutingDirection, via routeType: RouteType.Type, routing: (RouteType) -> Void) {
		routing(router(direction, for: routeType))
	}
}

public protocol Route: AnyObject {}

#if canImport(UIKit)
import UIKit

public protocol RouterAwareUIResponder: FirstRouterAware {}

public extension RouterAwareUIResponder where Self: UIResponder {
	/// Returns the first `Router` found in the `UIResponder` chain. Best used in simple navigation (when you are sure the router still exists, for example with direct touch handlers).
	var firstRouter: Router? {
		var current: UIResponder = self
		while true {
			if let router = current as? Router {
				return router
			} else if current != self, let firstRouterAware = current as? FirstRouterAware {
				return firstRouterAware.firstRouter
			} else if let next = current.next {
				current = next
			} else {
				return nil
			}
		}
	}
}

public protocol RouterAwareUIViewController: FirstRouterAware {}

public extension RouterAwareUIViewController where Self: UIViewController {
	/// Returns the first `Router` found in the `UIViewController` chain. Best used in simple navigation (when you are sure the router still exists, for example with direct touch handlers).
	var firstRouter: Router? {
		var current: UIViewController = self
		while true {
			if let router = current as? Router {
				return router
			} else if current != self, let firstRouterAware = current as? FirstRouterAware {
				return firstRouterAware.firstRouter
			} else if let next = current.parent {
				current = next
			} else {
				return nil
			}
		}
	}
}

public protocol UINavigationControllerRouter: Router {}

public extension UINavigationControllerRouter where Self: UINavigationController {
	var childRouters: [Router] {
		return [viewControllers.last].compactMap { $0 as? Router }
	}
}

public extension UINavigationControllerRouter where Self: NavigationControllerWrapper {
	var childRouters: [Router] {
		return [viewControllers.last].compactMap { $0 as? Router }
	}
}
#endif
