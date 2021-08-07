//
//  Created on 04/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(Combine)
import Combine

public class ValueResourceProviderFactory<Resource: Hashable>: ResourceProviderFactory {
	public init() {}

	public func create(for input: (value: Resource, identifier: String)) -> AnyResourceProvider<Resource> {
		return ValueResourceProvider<Resource>(value: input.value, identifier: input.identifier).eraseToAnyResourceProvider()
	}
}

public class ValueResourceProvider<Resource: Hashable>: ResourceProvider {
	private let value: Resource
	private let valueIdentifier: String

	public var identifier: String {
		return "ValueResourceProvider[identifier: \(valueIdentifier)]"
	}

	public init(value: Resource, identifier: String) {
		self.value = value
		valueIdentifier = identifier
	}

	public func resourceAndAwaitTimeMagnitude() -> (resource: AnyPublisher<Resource, Error>, awaitTimeMagnitude: AwaitTimeMagnitude?) {
		return (
			resource: Just(value)
				.setFailureType(to: Error.self)
				.eraseToAnyPublisher(),
			awaitTimeMagnitude: AwaitTimeMagnitude.none
		)
	}

	public static func == (lhs: ValueResourceProvider<Resource>, rhs: ValueResourceProvider<Resource>) -> Bool {
		return lhs.valueIdentifier == rhs.valueIdentifier && lhs.value == rhs.value
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(valueIdentifier)
		hasher.combine(value)
	}
}
#endif
