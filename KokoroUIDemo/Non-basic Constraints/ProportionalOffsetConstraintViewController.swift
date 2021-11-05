//
//  Created on 19/11/2020.
//  Copyright © 2020 Nanoray. All rights reserved.
//

import KokoroUI
import UIKit

protocol ProportionalOffsetConstraintRoute: Route {
	func showProportionalOffsetConstraint(animated: Bool)
}

class ProportionalOffsetConstraintViewController: UIViewController {
	private var anchorViewContainer: UIView!
	private var anchorView: UIView!
	private var x1Slider: UISlider!
	private var x2Slider: UISlider!
	private var ratioSlider: UISlider!
	private var offsetSlider: UISlider!

	private var constraint: ProportionalOffsetConstraint!
	private var leftConstraint: NSLayoutConstraint!
	private var rightConstraint: NSLayoutConstraint!

	init() {
		super.init(nibName: nil, bundle: nil)
		navigationItem.title = "ProportionalOffsetConstraint"
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		super.loadView()
		let constraints = ConstraintSession.current

		view.backgroundColor = .systemBackground

		UIStackView().with { [parent = view!] in
			$0.axis = .vertical
			$0.spacing = 20

			x1Slider = UISlider().with { [parent = $0] in
				$0.addTarget(self, action: #selector(didChangeX1SliderValue), for: .valueChanged)
				parent.addArrangedSubview($0)
			}

			x2Slider = UISlider().with { [parent = $0] in
				$0.addTarget(self, action: #selector(didChangeX2SliderValue), for: .valueChanged)
				parent.addArrangedSubview($0)
			}

			ratioSlider = UISlider().with { [parent = $0] in
				$0.value = 0.5
				$0.addTarget(self, action: #selector(didChangeRatioSliderValue), for: .valueChanged)
				parent.addArrangedSubview($0)
			}

			anchorViewContainer = UIView().with { [parent = $0] in
				anchorView = UIView().with { [parent = $0] in
					$0.backgroundColor = .systemTeal

					UIView().with { [parent = $0] in
						$0.backgroundColor = .label

						parent.addSubview($0)
						constraint = $0.horizontalProportionalOffset(.center, to: parent, ratio: 0.5)
						constraints += [
							$0.verticalEdgesToSuperview(),
							$0.width(of: 1.0 / UIScreen.main.scale),
							constraint,
						]
					}

					parent.addSubview($0)
					leftConstraint = $0.leftToSuperview()
					rightConstraint = $0.rightToSuperview()
					constraints += [
						$0.verticalEdgesToSuperview(),
						leftConstraint,
						rightConstraint,
					]
				}

				parent.addArrangedSubview($0)
			}

			parent.addSubview($0)
			constraints += $0.edges(to: parent.safeAreaLayoutGuide, insets: 20)
		}
	}

	@objc private func didChangeX1SliderValue() {
		leftConstraint.constant = CGFloat(x1Slider.value) * anchorViewContainer.frame.width * 0.5
	}

	@objc private func didChangeX2SliderValue() {
		rightConstraint.constant = -CGFloat(x2Slider.value) * anchorViewContainer.frame.width * 0.5
	}

	@objc private func didChangeRatioSliderValue() {
		constraint.ratio.width = CGFloat(ratioSlider.value)
	}
}
