//
//  Created on 15/08/2021.
//  Copyright © 2021 Nanoray. All rights reserved.
//

import KokoroUI
import UIKit

protocol CardDeckViewRoute: AnyObject {
	func showCardDeckView(animated: Bool)
}

class CardDeckViewController: UIViewController {
	private var cardDeckView: CardDeckView<UIView>!
	private var orientationSegmentedControl: UISegmentedControl!
	private var splitCardGroupPositionSegmentedControl: UISegmentedControl!
	private var splitSpacingLabel: UILabel!
	private var splitSpacingSlider: UISlider!
	private var maxGroupedSpacingLabel: UILabel!
	private var maxGroupedSpacingSwitch: UISwitch!
	private var maxGroupedSpacingSlider: UISlider!
	private var itemCountLabel: UILabel!
	private var itemCountStepper: UIStepper!

	private var items = [UIView]() {
		didSet {
			guard let cardDeckView = cardDeckView else { return }
			oldValue.forEach { $0.removeFromSuperview() }
			items.forEach { cardDeckView.addArrangedSubview($0) }
		}
	}

	private var cardDeckViewConstraints = [NSLayoutConstraint]() {
		didSet {
			oldValue.deactivate()
			cardDeckViewConstraints.activate()
		}
	}

	init() {
		super.init(nibName: nil, bundle: nil)
		items = [newItem(index: 0), newItem(index: 1), newItem(index: 2), newItem(index: 3)]
		navigationItem.title = "CardDeckView"
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		super.loadView()
		let constraints = ConstraintSession.current

		view.backgroundColor = .systemBackground

		let stack = UIStackView().with { [parent = view!] in
			$0.axis = .vertical
			$0.spacing = 12
			$0.isLayoutMarginsRelativeArrangement = true
			$0.layoutMargins = .init(insets: 20)

			UILabel().with { [parent = $0] in
				$0.textColor = .label
				$0.text = "Orientation"
				$0.setContentHuggingPriority(.required, for: .vertical)

				parent.addArrangedSubview($0)
				parent.setCustomSpacing(4, after: $0)
			}

			orientationSegmentedControl = UISegmentedControl(items: ["L⇨R", "R⇨L", "T⇨B", "B⇨T"]).with { [parent = $0] in
				$0.addTarget(self, action: #selector(didChangeOrientationSegmentedControlValue(_:)), for: .valueChanged)
				$0.selectedSegmentIndex = 0
				$0.setContentHuggingPriority(.required, for: .vertical)
				parent.addArrangedSubview($0)
			}

			UILabel().with { [parent = $0] in
				$0.textColor = .label
				$0.text = "Split Card Group Position"
				$0.setContentHuggingPriority(.required, for: .vertical)

				parent.addArrangedSubview($0)
				parent.setCustomSpacing(4, after: $0)
			}

			splitCardGroupPositionSegmentedControl = UISegmentedControl(items: ["Near", "Far"]).with { [parent = $0] in
				$0.addTarget(self, action: #selector(didChangeSplitCardGroupPositionSegmentedControlValue(_:)), for: .valueChanged)
				$0.selectedSegmentIndex = 0
				$0.setContentHuggingPriority(.required, for: .vertical)
				parent.addArrangedSubview($0)
			}

			splitSpacingLabel = UILabel().with { [parent = $0] in
				$0.textColor = .label
				$0.text = "Split Spacing"
				$0.setContentHuggingPriority(.required, for: .vertical)

				parent.addArrangedSubview($0)
				parent.setCustomSpacing(4, after: $0)
			}

			splitSpacingSlider = UISlider().with { [parent = $0] in
				$0.minimumValue = 0
				$0.maximumValue = 40
				$0.addTarget(self, action: #selector(didChangeSplitSpacingSliderValue(_:)), for: .valueChanged)
				$0.setContentHuggingPriority(.required, for: .vertical)
				parent.addArrangedSubview($0)
			}

			maxGroupedSpacingLabel = UILabel().with { [parent = $0] in
				$0.textColor = .label
				$0.text = "Max Grouped Spacing"
				$0.setContentHuggingPriority(.required, for: .vertical)

				parent.addArrangedSubview($0)
				parent.setCustomSpacing(4, after: $0)
			}

			UIStackView().with { [parent = $0] in
				$0.axis = .horizontal
				$0.spacing = 12

				maxGroupedSpacingSwitch = UISwitch().with { [parent = $0] in
					$0.addTarget(self, action: #selector(didChangeMaxGroupedSpacingSwitchValue(_:)), for: .valueChanged)
					parent.addArrangedSubview($0)
				}

				maxGroupedSpacingSlider = UISlider().with { [parent = $0] in
					$0.minimumValue = 0
					$0.maximumValue = 40
					$0.addTarget(self, action: #selector(didChangeMaxGroupedSpacingSliderValue(_:)), for: .valueChanged)
					$0.setContentHuggingPriority(.required, for: .vertical)
					parent.addArrangedSubview($0)
				}

				parent.addArrangedSubview($0)
			}

			UIStackView().with { [parent = $0] in
				$0.axis = .horizontal
				$0.distribution = .fillEqually
				$0.spacing = 12

				itemCountLabel = UILabel().with { [parent = $0] in
					$0.textColor = .label
					$0.setContentHuggingPriority(.required, for: .vertical)
					parent.addArrangedSubview($0)
				}

				itemCountStepper = UIStepper().with { [parent = $0] in
					$0.minimumValue = 0
					$0.maximumValue = 500
					$0.stepValue = 1
					$0.value = Double(items.count)
					$0.addTarget(self, action: #selector(didChangeItemCountStepperValue(_:)), for: .valueChanged)
					parent.addArrangedSubview($0)
				}

				parent.addArrangedSubview($0)
			}

			parent.addSubview($0)
			constraints += $0.horizontalEdges(to: parent.safeAreaLayoutGuide)
		}

		let cardDeckViewContainer = UIView().with { [parent = view!] in
			$0.backgroundColor = .secondarySystemBackground
			$0.setContentHuggingPriority(.defaultLow, for: .vertical)
			$0.setContentCompressionResistancePriority(.required, for: .vertical)

			cardDeckView = CardDeckView().with { [parent = $0] in
				$0.addObserver(self)
				$0.backgroundColor = .tertiarySystemBackground
				$0.contentInsets = .init(insets: 20)
				$0.setContentHuggingPriority(.defaultLow, for: .vertical)
				$0.setContentCompressionResistancePriority(.required, for: .vertical)

				parent.addSubview($0)
				constraints += $0.centerInSuperview()
			}

			parent.addSubview($0)
			constraints += $0.horizontalEdges(to: parent.safeAreaLayoutGuide)
		}

		constraints += [
			stack.top(to: view.safeAreaLayoutGuide),
			cardDeckViewContainer.topToBottom(of: stack),
			cardDeckViewContainer.bottom(to: view.safeAreaLayoutGuide),
		]

		updateSplitSpacingUI()
		updateMaxGroupedSpacingUI()
		updateItemCountUI()
		updateCardDeckViewConstraints()
		items.forEach { cardDeckView.addArrangedSubview($0) }
	}

	@objc private func didChangeOrientationSegmentedControlValue(_ sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
		case 0:
			cardDeckView.orientation = .leftToRight
		case 1:
			cardDeckView.orientation = .rightToLeft
		case 2:
			cardDeckView.orientation = .topToBottom
		case 3:
			cardDeckView.orientation = .bottomToTop
		default:
			fatalError("Unhandled")
		}
		updateCardDeckViewConstraints()
	}

	@objc private func didChangeSplitCardGroupPositionSegmentedControlValue(_ sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
		case 0:
			cardDeckView.splitCardGroupPosition = .near
		case 1:
			cardDeckView.splitCardGroupPosition = .far
		default:
			fatalError("Unhandled")
		}
	}

	@objc private func didChangeSplitSpacingSliderValue(_ sender: UISlider) {
		cardDeckView.splitSpacing = CGFloat(sender.value)
		updateSplitSpacingUI()
	}

	@objc private func didChangeMaxGroupedSpacingSwitchValue(_ sender: UISwitch) {
		cardDeckView.maxGroupedSpacing = sender.isOn ? 20 : nil
		updateMaxGroupedSpacingUI()
	}

	@objc private func didChangeMaxGroupedSpacingSliderValue(_ sender: UISlider) {
		cardDeckView.maxGroupedSpacing = CGFloat(sender.value)
		updateMaxGroupedSpacingUI()
	}

	@objc private func didChangeItemCountStepperValue(_ sender: UIStepper) {
		let targetCount = Int(sender.value)
		while items.count > targetCount {
			items.removeLast()
		}
		while items.count < targetCount {
			items.append(newItem(index: items.count))
		}
		updateItemCountUI()
	}

	private func newItem(index: Int) -> UIView {
		let colors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemTeal, .systemBlue, .systemPurple]
		return RoundedView().with {
			$0.rounding = .rectangle(radius: .points(16))

			UIButton(type: .system).with { [parent = $0] in
				$0.backgroundColor = colors[index % colors.count]
				$0.setTitle("B", for: .normal)

				parent.addSubview($0)
				$0.edgesToSuperview().activate()
			}
		}
	}

	private func updateCardDeckViewConstraints() {
		switch cardDeckView.orientation {
		case .leftToRight, .rightToLeft:
			cardDeckViewConstraints = cardDeckView.horizontalEdgesToSuperview() + [cardDeckView.height(of: 180).priority(.defaultHigh)]
		case .topToBottom, .bottomToTop:
			cardDeckViewConstraints = cardDeckView.verticalEdgesToSuperview() + [cardDeckView.width(of: 140).priority(.defaultHigh)]
		}
	}

	private func updateSplitSpacingUI() {
		splitSpacingLabel.text = "Split Spacing \(Int(cardDeckView.splitSpacing))"
		splitSpacingSlider.value = Float(cardDeckView.splitSpacing)
	}

	private func updateMaxGroupedSpacingUI() {
		maxGroupedSpacingLabel.text = "Max Grouped Spacing \(cardDeckView.maxGroupedSpacing.flatMap { "\(Int($0))" } ?? "off")"
		maxGroupedSpacingSwitch.setOn(cardDeckView.maxGroupedSpacing != nil, animated: false)
		if let value = cardDeckView.maxGroupedSpacing {
			maxGroupedSpacingSlider.setValue(Float(value), animated: false)
		}
	}

	private func updateItemCountUI() {
		itemCountLabel.text = "Items: \(items.count)"
	}
}

extension CardDeckViewController: CardDeckViewObserver {
	func didScroll(to position: CGFloat, in view: CardDeckView<UIView>) {
		print("didScroll(to: \(position), in: \(view))")
	}

	func didEndDragging(targetPosition: CGFloat, in view: CardDeckView<UIView>) {
		print("didEndDragging(targetPosition: \(targetPosition), in: \(view))")
	}
}
