//
//  Created on 25/07/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

#if canImport(Foundation)
import Foundation

public class KVOObserver: NSObject {
	private class Entry {
		private(set) weak var object: NSObject?
		let keyPath: String

		init(object: NSObject, keyPath: String) {
			self.object = object
			self.keyPath = keyPath
		}
	}

	private let callback: () -> Void
	private let lock: Lock = DefaultLock()
	private var observations = [Entry]()

	public init(callback: @escaping () -> Void) {
		self.callback = callback
	}

	deinit {
		stopObservingAll()
	}

	public func observe<Root: NSObject, Value>(_ keyPath: KeyPath<Root, Value>, of object: Root) {
		let keyPathString = NSExpression(forKeyPath: keyPath).keyPath
		lock.acquireAndRun {
			observations.append(.init(object: object, keyPath: keyPathString))
			object.addObserver(self, forKeyPath: keyPathString, options: [], context: nil)
		}
	}

	public func stopObserving<Root: NSObject, Value>(_ keyPath: KeyPath<Root, Value>, of object: Root) {
		let keyPathString = NSExpression(forKeyPath: keyPath).keyPath
		lock.acquireAndRun {
			if let index = observations.firstIndex(where: { $0.object === object && $0.keyPath == keyPathString }) {
				observations.remove(at: index)
				object.removeObserver(self, forKeyPath: keyPathString)
			}
		}
	}

	public func stopObservingAll() {
		lock.acquireAndRun {
			observations.forEach {
				$0.object?.removeObserver(self, forKeyPath: $0.keyPath)
			}
			observations.removeAll()
		}
	}

	// swiftlint:disable:next block_based_kvo
	public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		lock.acquireAndRun {
			for entry in observations {
				if entry.object === object as AnyObject && entry.keyPath == keyPath {
					callback()
					return
				}
			}
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
}
#endif
