//
//  Created on 28/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

public struct SetDifference<T: Hashable>: ValueWith, ExpressibleByArrayLiteral {
	public enum Element: Hashable {
		case with(_ element: T)
		case without(_ element: T)

		var element: T {
			switch self {
			case let .with(element), let .without(element):
				return element
			}
		}
	}

	fileprivate var instructions: [Element]

	public init() {
		instructions = []
	}

	public init(arrayLiteral elements: Element...) {
		var instructions = [Element]()
		elements.forEach { instruction in
			let element = instruction.element
			instructions.removeAll {
				switch $0 {
				case let .with(existingElement), let .without(existingElement):
					return existingElement == element
				}
			}
			switch instruction {
			case .with:
				instructions.append(.with(element))
			case .without:
				instructions.append(.without(element))
			}
		}
		self.instructions = instructions
	}

	public mutating func insert(_ element: T) {
		instructions.removeAll {
			switch $0 {
			case let .with(existingElement), let .without(existingElement):
				return existingElement == element
			}
		}
		instructions.append(.with(element))
	}

	public mutating func remove(_ element: T) {
		instructions.removeAll {
			switch $0 {
			case let .with(existingElement), let .without(existingElement):
				return existingElement == element
			}
		}
		instructions.append(.without(element))
	}
}

public extension Set {
	mutating func apply(_ difference: SetDifference<Element>) {
		difference.instructions.forEach {
			switch $0 {
			case let .with(element):
				insert(element)
			case let .without(element):
				remove(element)
			}
		}
	}

	func applying(_ difference: SetDifference<Element>) -> Set<Element> {
		var result = self
		difference.instructions.forEach {
			switch $0 {
			case let .with(element):
				result.insert(element)
			case let .without(element):
				result.remove(element)
			}
		}
		return result
	}
}
