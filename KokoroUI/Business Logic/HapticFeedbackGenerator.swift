//
//  Created on 06/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

#if canImport(UIKit)
import KokoroUtils
import UIKit

public class HapticFeedbackGenerator {
	public enum FeedbackType {
		case notification(_ type: Notification)
		case impact(_ style: Impact, intensity: CGFloat = 1.0)
		case selection

		public typealias Notification = UINotificationFeedbackGenerator.FeedbackType
		public typealias Impact = UIImpactFeedbackGenerator.FeedbackStyle
	}

	private lazy var notificationFeedbackGenerator = UINotificationFeedbackGenerator()
	private lazy var selectionFeedbackGenerator = UISelectionFeedbackGenerator()
	private var impactFeedbackGenerators = [FeedbackType.Impact: UIImpactFeedbackGenerator]()

	public init() {}

	public func prepare(_ feedbackType: FeedbackType) {
		switch feedbackType {
		case .notification:
			notificationFeedbackGenerator.prepare()
		case let .impact(style, _):
			impactFeedbackGenerators.computeIfAbsent(for: style) { UIImpactFeedbackGenerator(style: $0) }.prepare()
		case .selection:
			selectionFeedbackGenerator.prepare()
		}
	}

	public func generate(_ feedbackType: FeedbackType) {
		switch feedbackType {
		case let .notification(type):
			notificationFeedbackGenerator.notificationOccurred(type)
		case let .impact(style, intensity):
			impactFeedbackGenerators.computeIfAbsent(for: style) { UIImpactFeedbackGenerator(style: $0) }.impactOccurred(intensity: intensity)
		case .selection:
			selectionFeedbackGenerator.selectionChanged()
		}
	}
}
#endif
