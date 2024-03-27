import UIKit
import Fx

open class Button: UIButton {
	public var isHighlightedDidSet: ((Bool) -> Void)?
	public var isSelectedDidSet: ((Bool) -> Void)?
	public var isEnabledDidSet: ((Bool) -> Void)?
	public var minimumTapArea: CGSize = .square(44)
	public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle?

	public override var isHighlighted: Bool {
		didSet { isHighlightedDidSet?(isHighlighted) }
	}

	public override var isSelected: Bool {
		didSet { isSelectedDidSet?(isSelected) }
	}

	public override var isEnabled: Bool {
		didSet { isEnabledDidSet?(isEnabled) }
	}

	public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		let bounds = self.bounds
		return bounds.insetBy(
			dx: -max(0, minimumTapArea.width - bounds.width) / 2,
			dy: -max(0, minimumTapArea.height - bounds.height) / 2
		)
		.contains(point)
	}

	open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if let style = feedbackStyle {
			FeedbackGenerator.impact(style: style).trigger()
		}
		super.touchesBegan(touches, with: event)
	}
}

public extension ViewStyle where View == Button {

	static func highlightedBackgroundColorAnimation(normal: UIColor, highlighted: UIColor) -> Self {
		Self { button in
			button.backgroundColor = button.isHighlighted ? highlighted : normal
			button.isHighlightedDidSet = { [weak button] isHighlighted in
				UIView.animate(withDuration: 0.1, delay: 0, options: .beginFromCurrentState, animations: {
					button?.backgroundColor = isHighlighted ? highlighted : normal
				})
			}
		}
	}
}
