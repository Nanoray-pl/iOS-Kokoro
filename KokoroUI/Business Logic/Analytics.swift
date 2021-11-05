//
//  Created on 05/11/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public enum AnalyticsCollectionPreferenceState {
	case notDetermined, declined, authorized
}

public protocol AnalyticsCollectionPreferenceStateObserver: AnyObject {
	func didChangeAnalyticsCollectionPreferenceState(to state: AnalyticsCollectionPreferenceState, in analytics: UntypedAnalytics)
}

public protocol Analytics: AnyObject {
	associatedtype AnalyticsEvent

	var identifier: ObjectIdentifier { get }
	var collectionPreferenceState: AnalyticsCollectionPreferenceState { get set }

	func setUserId(_ id: String?)
	func logEvent(_ event: AnalyticsEvent)
	func addObserver(_ observer: AnalyticsCollectionPreferenceStateObserver)
	func removeObserver(_ observer: AnalyticsCollectionPreferenceStateObserver)
}

public extension Analytics {
	func eraseToUntypedAnalytics() -> UntypedAnalytics {
		return UntypedAnalytics(wrapping: self)
	}

	func eraseToAnyAnalytics() -> AnyAnalytics<AnalyticsEvent> {
		return (self as? AnyAnalytics<AnalyticsEvent>) ?? .init(wrapping: self)
	}
}

public class UntypedAnalytics {
	public let identifier: ObjectIdentifier
	private let addObserverClosure: (AnalyticsCollectionPreferenceStateObserver) -> Void
	private let removeObserverClosure: (AnalyticsCollectionPreferenceStateObserver) -> Void

	public init<AnalyticsType: Analytics>(wrapping wrapped: AnalyticsType) {
		identifier = wrapped.identifier
		addObserverClosure = { wrapped.addObserver($0) }
		removeObserverClosure = { wrapped.removeObserver($0) }
	}

	public func addObserver(_ observer: AnalyticsCollectionPreferenceStateObserver) {
		addObserverClosure(observer)
	}

	public func removeObserver(_ observer: AnalyticsCollectionPreferenceStateObserver) {
		removeObserverClosure(observer)
	}
}

public class AnyAnalytics<AnalyticsEvent>: Analytics {
	public let identifier: ObjectIdentifier
	private let collectionPreferenceStateClosure: () -> AnalyticsCollectionPreferenceState
	private let setCollectionPreferenceStateClosure: (AnalyticsCollectionPreferenceState) -> Void
	private let setUserIdClosure: (String?) -> Void
	private let logEventClosure: (AnalyticsEvent) -> Void
	private let addObserverClosure: (AnalyticsCollectionPreferenceStateObserver) -> Void
	private let removeObserverClosure: (AnalyticsCollectionPreferenceStateObserver) -> Void

	public var collectionPreferenceState: AnalyticsCollectionPreferenceState {
		get {
			return collectionPreferenceStateClosure()
		}
		set {
			setCollectionPreferenceStateClosure(newValue)
		}
	}

	public init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: Analytics, Wrapped.AnalyticsEvent == AnalyticsEvent {
		identifier = wrapped.identifier
		collectionPreferenceStateClosure = { wrapped.collectionPreferenceState }
		setCollectionPreferenceStateClosure = { wrapped.collectionPreferenceState = $0 }
		setUserIdClosure = { wrapped.setUserId($0) }
		logEventClosure = { wrapped.logEvent($0) }
		addObserverClosure = { wrapped.addObserver($0) }
		removeObserverClosure = { wrapped.removeObserver($0) }
	}

	public func setUserId(_ id: String?) {
		setUserIdClosure(id)
	}

	public func logEvent(_ event: AnalyticsEvent) {
		logEventClosure(event)
	}

	public func addObserver(_ observer: AnalyticsCollectionPreferenceStateObserver) {
		addObserverClosure(observer)
	}

	public func removeObserver(_ observer: AnalyticsCollectionPreferenceStateObserver) {
		removeObserverClosure(observer)
	}
}

public protocol AnalyticsEngine: AnyObject {
	associatedtype AnalyticsEvent

	func setAnalyticsCollectionEnabled(_ analyticsCollectionEnabled: Bool)
	func setUserId(_ id: String?)
	func logEvent(_ event: AnalyticsEvent)
}

public extension AnalyticsEngine {
	func eraseToAnyAnalyticsEngine() -> AnyAnalyticsEngine<AnalyticsEvent> {
		return (self as? AnyAnalyticsEngine<AnalyticsEvent>) ?? .init(wrapping: self)
	}
}

public class AnyAnalyticsEngine<AnalyticsEvent>: AnalyticsEngine {
	private let setAnalyticsCollectionEnabledClosure: (Bool) -> Void
	private let setUserIdClosure: (String?) -> Void
	private let logEventClosure: (AnalyticsEvent) -> Void

	public init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: AnalyticsEngine, Wrapped.AnalyticsEvent == AnalyticsEvent {
		setAnalyticsCollectionEnabledClosure = { wrapped.setAnalyticsCollectionEnabled($0) }
		setUserIdClosure = { wrapped.setUserId($0) }
		logEventClosure = { wrapped.logEvent($0) }
	}

	public func setAnalyticsCollectionEnabled(_ analyticsCollectionEnabled: Bool) {
		setAnalyticsCollectionEnabledClosure(analyticsCollectionEnabled)
	}

	public func setUserId(_ id: String?) {
		setUserIdClosure(id)
	}

	public func logEvent(_ event: AnalyticsEvent) {
		logEventClosure(event)
	}
}

public protocol AnalyticsScreen {
	var analyticsKey: String { get }
	var analyticsClass: String? { get }
}

public protocol AnalyticsScreenClass: AnalyticsScreen {
	static var analyticsKey: String { get }
	static var analyticsClass: String? { get }
}

public extension AnalyticsScreen {
	var analyticsClass: String? {
		return "\(type(of: self))"
	}
}

public extension AnalyticsScreen where Self: AnalyticsScreenClass {
	var analyticsKey: String {
		return Self.analyticsKey
	}
}

public extension AnalyticsScreenClass {
	static var analyticsClass: String? {
		return "\(self)"
	}
}

public class CompoundAnalyticsEngine<AnalyticsEvent>: AnalyticsEngine {
	private let analyticsEngines: [AnyAnalyticsEngine<AnalyticsEvent>]

	public init(with analyticsEngines: [AnyAnalyticsEngine<AnalyticsEvent>]) {
		self.analyticsEngines = analyticsEngines
	}

	public func setAnalyticsCollectionEnabled(_ analyticsCollectionEnabled: Bool) {
		analyticsEngines.forEach { $0.setAnalyticsCollectionEnabled(analyticsCollectionEnabled) }
	}

	public func setUserId(_ id: String?) {
		analyticsEngines.forEach { $0.setUserId(id) }
	}

	public func logEvent(_ event: AnalyticsEvent) {
		analyticsEngines.forEach { $0.logEvent(event) }
	}
}
