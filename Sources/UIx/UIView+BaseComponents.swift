import UIKit
import Fx

public let CenterX = HStack(alignment: .center) • lift
public let CenterY = VStack(alignment: .center) • lift
public let CenterXY = CenterX • CenterY

public extension UIView {
	static func button(style: ViewStyle<Button>, action: @escaping (Button) -> Void) -> UIView {
		with(Button()) {
			$0.applyStyle(style)
			$0.setButtonAction(action)
		}
	}
}

public extension UIView {
	static func image(_ image: UIImage? = nil, style: ViewStyle<UIImageView> = .empty) -> UIView {
		UIImageView(image: image).applyingStyle § style
	}
	static func image(_ image: Property<UIImage?>, style: ViewStyle<UIImageView> = .empty) -> UIView {
		UIImageView().applyingStyle § ∑[.binding(\.image, to: image), style]
	}
}

public extension UIView {
	static func color(_ color: Property<UIColor>) -> UIView {
		UIView().applyingStyle § .binding(\.backgroundColor, to: color)
	}
}

public extension UIView {

	static func line(text: NSAttributedString, labelStyle: ViewStyle<UILabel> = .empty) -> UIView {
		UILabel().applyingStyle § ∑[
			.assigning(\.attributedText, to: text),
			labelStyle
		]
	}
	static func line(text: Property<NSAttributedString>, labelStyle: ViewStyle<UILabel> = .empty) -> UIView {
		UILabel().applyingStyle § ∑[
			.binding(\.attributedText, to: text),
			labelStyle
		]
	}
}
