//
//  Created on 06/06/2022.
//  Copyright © 2022 Nanoray. All rights reserved.
//

#if swift(>=5.6)
public struct AnyAsyncSequence<Element>: AsyncSequence {
	public typealias AsyncIterator = AnyAsyncIterator<Element>

	private let makeAsyncIteratorClosure: () -> AsyncIterator

	public init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: AsyncSequence, Wrapped.Element == Element {
		makeAsyncIteratorClosure = { wrapped.makeAsyncIterator().eraseToAnyAsyncIterator() }
	}

	public func makeAsyncIterator() -> AsyncIterator {
		return makeAsyncIteratorClosure()
	}
}

public struct AnyAsyncIterator<Element>: AsyncIteratorProtocol {
	private let nextClosure: () async throws -> Element?

	public init<Wrapped>(wrapping wrapped: Wrapped) where Wrapped: AsyncIteratorProtocol, Wrapped.Element == Element {
		var mutableWrapped = wrapped
		nextClosure = { try await mutableWrapped.next() }
	}

	public mutating func next() async throws -> Element? {
		return try await nextClosure()
	}
}

public extension AsyncIteratorProtocol {
	func eraseToAnyAsyncIterator() -> AnyAsyncIterator<Element> {
		return (self as? AnyAsyncIterator<Element>) ?? .init(wrapping: self)
	}
}

public extension AsyncSequence {
	func eraseToAnyAsyncSequence() -> AnyAsyncSequence<Element> {
		return (self as? AnyAsyncSequence<Element>) ?? .init(wrapping: self)
	}
}
#endif
