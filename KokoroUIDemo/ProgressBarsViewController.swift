//
//  Created on 11/10/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUI
import UIKit

protocol ProgressBarsRoute: class {
	func showProgressBars(animated: Bool)
}

class ProgressBarsViewController: UIViewController {
	private static let shortProgressBarLength: CGFloat = 6

	private var horizontalProgressBar: ProgressBar!
	private var verticalProgressBar: ProgressBar!
	private var indeterminateSwitch: UISwitch!
	private var valueSlider: UISlider!
	private var valueLabel: UILabel!
	private var reverseSwitch: UISwitch!

	init() {
		super.init(nibName: nil, bundle: nil)
		navigationItem.title = "Progress Bars"
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		super.loadView()
		var constraints = ConstraintSet()
		defer { constraints.activate() }

		view.backgroundColor = .systemBackground

		verticalProgressBar = ProgressBar(direction: .bottomToTop).with { [parent = view!] in
			parent.addSubview($0)
			constraints += [
				$0.width(of: Self.shortProgressBarLength),
				$0.leading(to: parent.safeAreaLayoutGuide, inset: 20),
			]
		}

		horizontalProgressBar = ProgressBar(direction: .leadingToTrailing).with { [parent = view!] in
			parent.addSubview($0)
			constraints += [
				$0.height(of: Self.shortProgressBarLength),
				$0.top(to: parent.safeAreaLayoutGuide, inset: 20),
				$0.trailing(to: parent.safeAreaLayoutGuide, inset: 20),
			]
		}

		UIStackView().with { [parent = view!] in
			$0.axis = .vertical
			$0.spacing = 20

			RoundedView().with { [parent = $0] in
				$0.backgroundColor = .systemGroupedBackground
				$0.rounding = .rectangle(corners: .allCorners, radius: .points(12))

				UIStackView().with { [parent = $0] in
					$0.axis = .vertical
					$0.spacing = 12
					$0.isLayoutMarginsRelativeArrangement = true
					$0.layoutMargins = .init(insets: 12)

					UILabel().with { [parent = $0] in
						$0.font = .systemFont(ofSize: 18, weight: .semibold)
						$0.textColor = .label
						$0.text = "Value"

						parent.addArrangedSubview($0)
					}

					UIStackView().with { [parent = $0] in
						$0.axis = .horizontal
						$0.spacing = 12

						UILabel().with { [parent = $0] in
							$0.font = .systemFont(ofSize: 17, weight: .regular)
							$0.textColor = .label
							$0.text = "Indeterminate"

							parent.addArrangedSubview($0)
						}

						indeterminateSwitch = UISwitch().with { [parent = $0] in
							$0.addTarget(self, action: #selector(didToggleIndeterminateSwitch), for: .valueChanged)
							parent.addArrangedSubview($0)
						}

						parent.addArrangedSubview($0)
					}

					UIStackView().with { [parent = $0] in
						$0.axis = .horizontal
						$0.spacing = 12

						valueSlider = UISlider().with { [parent = $0] in
							$0.value = 0.3
							$0.addTarget(self, action: #selector(didChangeSliderValue), for: .valueChanged)

							parent.addArrangedSubview($0)
						}

						valueLabel = UILabel().with { [parent = $0] in
							$0.font = .systemFont(ofSize: 17, weight: .regular)
							$0.textColor = .label

							parent.addArrangedSubview($0)
						}

						parent.addArrangedSubview($0)
					}

					parent.addSubview($0)
					constraints += $0.edgesToSuperview()
				}

				parent.addArrangedSubview($0)
			}

			RoundedView().with { [parent = $0] in
				$0.backgroundColor = .systemGroupedBackground
				$0.rounding = .rectangle(corners: .allCorners, radius: .points(12))

				UIStackView().with { [parent = $0] in
					$0.axis = .horizontal
					$0.spacing = 12
					$0.isLayoutMarginsRelativeArrangement = true
					$0.layoutMargins = .init(insets: 12)

					UILabel().with { [parent = $0] in
						$0.font = .systemFont(ofSize: 17, weight: .regular)
						$0.textColor = .label
						$0.text = "Reverse"

						parent.addArrangedSubview($0)
					}

					reverseSwitch = UISwitch().with { [parent = $0] in
						$0.addTarget(self, action: #selector(didToggleReverseSwitch), for: .valueChanged)
						parent.addArrangedSubview($0)
					}

					parent.addSubview($0)
					constraints += $0.edgesToSuperview()
				}

				parent.addArrangedSubview($0)
			}

			parent.addSubview($0)
			constraints += [
				$0.top(to: verticalProgressBar),
				$0.horizontalEdges(to: horizontalProgressBar),
			]
		}

		constraints += [
			verticalProgressBar.topToBottom(of: horizontalProgressBar, inset: 20),
			horizontalProgressBar.leadingToTrailing(of: verticalProgressBar, inset: 20),
			verticalProgressBar.heightToWidth(of: horizontalProgressBar),
		]

		updateValue()
	}

	private func updateValue() {
		valueLabel.text = "\(Int(valueSlider.value * 100))%"
		indeterminateSwitch.setOn(false, animated: Animated.motionBased.value)
		horizontalProgressBar.setValue(.determinate(Double(valueSlider.value)), animated: false)
		verticalProgressBar.setValue(.determinate(Double(valueSlider.value)), animated: false)
	}

	@objc private func didToggleIndeterminateSwitch() {
		if indeterminateSwitch.isOn {
			horizontalProgressBar.setValue(.indeterminate, animated: false)
			verticalProgressBar.setValue(.indeterminate, animated: false)
		} else {
			updateValue()
		}
	}

	@objc private func didChangeSliderValue() {
		updateValue()
	}

	@objc private func didToggleReverseSwitch() {
		horizontalProgressBar.direction = (reverseSwitch.isOn ? .trailingToLeading : .leadingToTrailing)
		verticalProgressBar.direction = (reverseSwitch.isOn ? .topToBottom : .bottomToTop)
	}
}
