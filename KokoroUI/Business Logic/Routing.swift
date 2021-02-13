//
//  Created on 13/02/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import UIKit

public protocol Router: class {
	var parentRouter: Router? { get }
	var childRouters: [Router] { get }
}

public protocol Route: class {}

public enum RoutingDirection {
	/// Route via the first known upstream (parent) router. Best used if context is known (simple navigation) - for example with navigation controllers.
	case upstream

	/// Route via the last known downstream (child) router. Best used if context is unknown and the base router is near the top of the view hierarchy - for example for modal alerts, with `UIApplication` as the base router.
	case downstream

	/// Try routing `.downstream` first, and if that fails, `.upstream`. Best used if the base router is of unknown origin.
	case anyDirection
}

public extension UIResponder {
	/// Returns the first `Router` found in the `UIResponder` chain. Best used in simple navigation (when you are sure the router still exists, for example with direct touch handlers).
	var firstRouter: Router? {
		var current = self
		while true {
			if let router = current as? Router {
				return router
			}
			if let next = current.next {
				current = next
			} else {
				return nil
			}
		}
	}

	/// Returns the root `Router` of this `UIResponder` chain, as in the one with no parent. Best used in complex navigation (when you are not sure `firstRouter` would still exist, for example after receiving a HTTP response).
	var rootRouter: Router? {
		guard var current = firstRouter else { return nil }
		while true {
			if let next = current.parentRouter {
				current = next
			} else {
				break
			}
		}
		return current
	}

	func optionalRouter<RouteType>(_ direction: RoutingDirection = .anyDirection, for routeType: RouteType.Type) -> RouteType? {
		return firstRouter?.optionalRouter(direction, for: routeType)
	}

	/// - Warning: This method will call `fatalError` if it cannot find the specific router.
	func router<RouteType>(_ direction: RoutingDirection = .anyDirection, for routeType: RouteType.Type) -> RouteType {
		guard let firstRouter = firstRouter else { fatalError("\(self) does not have a `Router` in its `UIResponder` chain.") }
		return firstRouter.router(direction, for: routeType)
	}

	func route<RouteType>(_ direction: RoutingDirection = .anyDirection, via routeType: RouteType.Type, routing: (RouteType) -> Void) {
		guard let firstRouter = firstRouter else { fatalError("\(self) does not have a `Router` in its `UIResponder` chain.") }
		firstRouter.route(direction, via: routeType, routing: routing)
	}
}

public extension Router {
	private func firstUpstreamRouter<RouteType>(for routeType: RouteType.Type) -> RouteType? {
		return (self as? RouteType) ?? parentRouter?.firstUpstreamRouter(for: routeType)
	}

	private func lastDownstreamRouter<RouteType>(for routeType: RouteType.Type) -> RouteType? {
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

	func optionalRouter<RouteType>(_ direction: RoutingDirection = .anyDirection, for routeType: RouteType.Type) -> RouteType? {
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

	/// - Warning: This method will call `fatalError` if it cannot find the specific router.
	func router<RouteType>(_ direction: RoutingDirection = .anyDirection, for routeType: RouteType.Type) -> RouteType {
		guard let router = optionalRouter(direction, for: routeType) else { fatalError("No known router handling \(routeType).") }
		return router
	}

	func route<RouteType>(_ direction: RoutingDirection = .anyDirection, via routeType: RouteType.Type, routing: (RouteType) -> Void) {
		routing(router(direction, for: routeType))
	}
}
