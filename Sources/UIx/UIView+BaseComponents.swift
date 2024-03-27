import UIKit
import Fx

public let CenterX = HStack(alignment: .center) • const
public let CenterY = VStack(alignment: .center) • const
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
	static func line(text: String, style: TextStyle, labelStyle: ViewStyle<UILabel> = .empty) -> UIView {
		UILabel().applyingStyle § ∑[
			.assigning(\.attributedText, to: .make(string: text, style: style)),
			labelStyle
		]
	}
	static func line(text: Property<String>, style: TextStyle, labelStyle: ViewStyle<UILabel> = .empty) -> UIView {
		UILabel().applyingStyle § ∑[
			.binding(\.attributedText, to: text.map { .make(string: $0, style: style) }),
			labelStyle
		]
	}

	static func lines(text: NSAttributedString, labelStyle: ViewStyle<UILabel> = .empty) -> UIView {
		LayoutView(multilineLabel: UILabel().applyingStyle § ∑[
			.assigning(\.attributedText, to: text),
			.multiline(),
			labelStyle
		])
	}
	static func lines(text: Property<NSAttributedString>, labelStyle: ViewStyle<UILabel> = .empty) -> UIView {
		LayoutView(multilineLabel: UILabel().applyingStyle § ∑[
			.binding(\.attributedText, to: text),
			.multiline(),
			labelStyle
		])
	}
	static func lines(text: String, style: TextStyle, labelStyle: ViewStyle<UILabel> = .empty) -> UIView {
		LayoutView(multilineLabel: UILabel().applyingStyle § ∑[
			.assigning(\.attributedText, to: .make(string: text, style: style)),
			.multiline(),
			labelStyle
		])
	}
	static func lines(text: Property<String>, style: TextStyle, labelStyle: ViewStyle<UILabel> = .empty) -> UIView {
		LayoutView(multilineLabel: UILabel().applyingStyle § ∑[
			.binding(\.attributedText, to: text.map { .make(string: $0, style: style) }),
			.multiline(),
			labelStyle
		])
	}
}
