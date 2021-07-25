//
//  Created on 26/02/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

/// A collection storing weak references to objects, with optional additional stored parameters for each of them.
/// - Note: If none additional stored parameters are wanted, `Void` should be used for the `AdditionalObserverParameters` type.
public final class BoxingObserverSet<Observer, AdditionalObserverParameters> {
	private final class WeakBox {
		private(set) weak var observer: AnyObject?
		let parameters: AdditionalObserverParameters

		init(wrapping observer: AnyObject, parameters: AdditionalObserverParameters) {
			self.observer = observer
			self.parameters = parameters
		}
	}

	private let boxedObservers = BoxedObserverSet<WeakBox, ObjectIdentifier?>(
		isValid: { $0.observer != nil },
		identity: { $0.observer.flatMap { ObjectIdentifier($0) } }
	)

	public var observers: [Observer] {
		return boxedObservers.observers.compactMap { $0.observer as? Observer }
	}

	public var observersWithParameters: [(observer: Observer, parameters: AdditionalObserverParameters)] {
		return boxedObservers.observers.compactMap {
			if let observer = $0.observer as? Observer {
				return (observer: observer, parameters: $0.parameters)
			} else {
				return nil
			}
		}
	}

	public init() {}

	public func observers<SpecializedObserver>(ofType type: SpecializedObserver.Type) -> [SpecializedObserver] {
		return self.observers.compactMap { $0 as? SpecializedObserver }
	}

	public func observersWithParameters<SpecializedObserver>(ofType type: SpecializedObserver.Type) -> [(observer: SpecializedObserver, parameters: AdditionalObserverParameters)] {
		return self.observersWithParameters.compactMap { observer, parameters in
			if let observer = observer as? SpecializedObserver {
				return (observer: observer, parameters: parameters)
			} else {
				return nil
			}
		}
	}

	public func insert(_ observer: Observer, parameters: AdditionalObserverParameters) {
		boxedObservers.insert(.init(wrapping: observer as AnyObject, parameters: parameters))
	}

	public func remove(_ observer: Observer) {
		boxedObservers.remove(withIdentity: ObjectIdentifier(observer as AnyObject))
	}

	public func removeAll() {
		boxedObservers.removeAll()
	}

	public func forEach(_ closure: (_ observer: Observer, _ parameters: AdditionalObserverParameters) -> Void) {
		observersWithParameters.forEach { closure($0.observer, $0.parameters) }
	}

	public func forEach(_ closure: (_ observer: Observer) -> Void) {
		observers.forEach { closure($0) }
	}

	public func forEach<SpecializedObserver>(_ type: SpecializedObserver.Type, _ closure: (_ observer: SpecializedObserver, _ parameters: AdditionalObserverParameters) -> Void) {
		observersWithParameters(ofType: type).forEach { closure($0.observer, $0.parameters) }
	}

	public func forEach<SpecializedObserver>(ofType type: SpecializedObserver.Type, _ closure: (_ observer: SpecializedObserver) -> Void) {
		observers(ofType: type).forEach { closure($0) }
	}
}

public extension BoxingObserverSet where AdditionalObserverParameters == Void {
	func insert(_ observer: Observer) {
		insert(observer, parameters: ())
	}
}

/// A collection storing strong references to objects which are already wrapping weak references.
public final class BoxedObserverSet<BoxedObserver, ID: Equatable> {
	private var isValidClosure: (BoxedObserver) -> Bool
	private var identityClosure: (BoxedObserver) -> ID

	public var observers: [BoxedObserver] {
		cleanUp()
		return boxes.filter { isValidClosure($0) }
	}

	private var boxes = [BoxedObserver]()

	public init(isValid isValidClosure: @escaping (BoxedObserver) -> Bool, identity identityClosure: @escaping (BoxedObserver) -> ID) {
		self.isValidClosure = isValidClosure
		self.identityClosure = identityClosure
	}

	private func cleanUp() {
		boxes = boxes.filter { isValidClosure($0) }
	}

	public func insert(_ observer: BoxedObserver) {
		remove(observer)
		boxes.append(observer)
	}

	public func remove(withIdentity identity: ID) {
		cleanUp()
		boxes.removeFirst { identityClosure($0) == identity }
	}

	public func remove(_ observer: BoxedObserver) {
		remove(withIdentity: identityClosure(observer))
	}

	public func removeAll() {
		boxes.removeAll()
	}

	public func forEach(_ closure: (_ observer: BoxedObserver) -> Void) {
		observers.forEach { closure($0) }
	}
}

public extension BoxedObserverSet where BoxedObserver: Equatable, ID == BoxedObserver {
	convenience init(isValid isValidClosure: @escaping (BoxedObserver) -> Bool) {
		self.init(isValid: isValidClosure, identity: { $0 })
	}
}
