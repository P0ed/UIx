import UIKit
import Fx

public struct ViewStyle<View: UIView> {
	public var apply: (View) -> Void

	public init(apply: @escaping (View) -> Void) {
		self.apply = apply
	}
}

extension ViewStyle: Monoid {
	public static var empty: ViewStyle { ViewStyle { _ in } }
	public mutating func combine(_ x: ViewStyle<View>) {
		apply = { [apply] view in apply(view); x.apply(view) }
	}
}

public protocol Stylable {}
extension UIView: Stylable {}

public extension Stylable where Self: UIView {
	func applyStyle(_ style: ViewStyle<Self>) {
		style.apply(self)
	}
	func applyingStyle(_ style: ViewStyle<Self>) -> Self {
		with(self, style.apply)
	}
}

// MARK: - Common implementations:
public extension ViewStyle {

	static func color(_ color: UIColor) -> ViewStyle {
		Self { $0.backgroundColor = color }
	}
	static func color(_ color: Property<UIColor>) -> ViewStyle {
		.binding(\.backgroundColor, to: color)
	}

	static func subscribing(_ generator: @escaping (View) -> Disposable) -> ViewStyle {
		Self { $0.lifetime += generator($0) }
	}
	static func subscribing(_ disposable: Disposable) -> ViewStyle {
		Self { $0.lifetime += disposable }
	}

	static func assigning<A>(_ keyPath: ReferenceWritableKeyPath<View, A>, to value: A) -> ViewStyle {
		Self { $0[keyPath: keyPath] = value }
	}
	static func binding<A>(_ keyPath: ReferenceWritableKeyPath<View, A>, to value: Property<A>) -> ViewStyle {
		Self { $0.bind(keyPath, to: value) }
	}
	static func binding<A>(_ keyPath: ReferenceWritableKeyPath<View, A?>, to value: Property<A>) -> ViewStyle {
		Self { $0.bind(keyPath, to: value) }
	}

	static func hidden(_ isHidden: Property<Bool>) -> ViewStyle {
		.binding(\.isHidden, to: isHidden)
	}

	static func animating<A: Equatable>(
		_ keyPath: ReferenceWritableKeyPath<View, A>,
		in duration: TimeInterval = 0.2,
		with value: Property<A>
	) -> ViewStyle {
		Self { view in
			view.apply(value) { view, value in
				guard view[keyPath: keyPath] != value else { return }
				UIView.animate(
					withDuration: duration,
					delay: 0,
					options: .beginFromCurrentState,
					animations: { view[keyPath: keyPath] = value }
				)
			}
		}
	}

	static func roundCorners(_ radius: CGFloat) -> ViewStyle {
		Self {
			$0.layer.cornerRadius = radius
			$0.layer.masksToBounds = true
		}
	}

	static func size(_ size: CGSize) -> ViewStyle {
		Self { $0.matchSize(to: size) }
	}

	static func width(_ width: CGFloat) -> ViewStyle {
		Self { $0.matchWidth(to: width) }
	}
	static func height(_ height: CGFloat) -> ViewStyle {
		Self { $0.matchHeight(to: height) }
	}
	static func ratio(_ ratio: CGFloat) -> ViewStyle {
		Self { $0.widthAnchor.constraint(equalTo: $0.heightAnchor, multiplier: ratio).isActive = true }
	}

	static func circle(diameter: CGFloat) -> ViewStyle {
		∑[.size(.square(diameter)), roundCorners(diameter / 2)]
	}

	static func pill(height: CGFloat) -> ViewStyle {
		∑[.roundCorners(height / 2), .height(height)]
	}

	static func pill(height: Property<CGFloat>) -> ViewStyle {
		.subscribing { $0.apply(height) { $0.applyStyle(.roundCorners($1 / 2)) } }
	}

	static func border(width: CGFloat, color: UIColor) -> ViewStyle {
		Self {
			$0.layer.borderColor = color.cgColor
			$0.layer.borderWidth = width
		}
	}

	static func contentMode(_ mode: UIView.ContentMode) -> ViewStyle {
		Self { $0.contentMode = mode }
	}

	static func hugging(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis? = nil) -> ViewStyle {
		Self { view in
			(axis.map { [$0] } ?? [.horizontal, .vertical]).forEach { axis in
				view.setContentHuggingPriority(priority, for: axis)
			}
		}
	}
	static func compressionResistance(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis? = nil) -> ViewStyle {
		Self { view in
			(axis.map { [$0] } ?? [.horizontal, .vertical]).forEach { axis in
				view.setContentCompressionResistancePriority(priority, for: axis)
			}
		}
	}

	static func tintColor(_ color: UIColor?) -> ViewStyle {
		Self { $0.tintColor = color }
	}

	static var becomeFirstResponder: ViewStyle {
		Self { $0.becomeFirstResponder() }
	}

	static func subview(insets: Property<UIEdgeInsets>, view: UIView) -> ViewStyle {
		Self { container in
			let constraints = container.pinSubview(view)
			container.apply(insets) { _, insets in constraints.setInsets(insets) }
		}
	}
}

public extension ViewStyle where View: UIButton {

	static func action(_ action: @escaping (View) -> Void) -> ViewStyle {
		ViewStyle { $0.setButtonAction(action) }
	}

//	static func text(text: Property<String>, style: TextStyle = .empty, color: UIColor, highlighted: UIColor? = nil, labelStyle: ViewStyle<UILabel> = .empty) -> ViewStyle {
//		ViewStyle {
//			$0.apply(text) { button, text in
//				let highlighted = highlighted ?? color.darker
//				button.setAttributedTitle(.make(string: text, style: style.colored(color)), for: .normal)
//				button.setAttributedTitle(.make(string: text, style: style.colored(highlighted)), for: .highlighted)
//				button.titleLabel.map(labelStyle.apply)
//			}
//		}
//	}

	static func image(_ image: UIImage?) -> ViewStyle {
		Self { $0.setImage(image, for: .normal) }
	}

	static func content(insets: UIEdgeInsets = .zero, _ view: UIView) -> ViewStyle {
		Self { button in
			view.isUserInteractionEnabled = false
			button.pinSubview(view, insets: insets)
		}
	}
}

public struct ControlState {
	public var isEnabled: Bool
	public var isSelected: Bool
	public var isHighlighted: Bool

	public init(isEnabled: Bool, isSelected: Bool, isHighlighted: Bool) {
		self.isEnabled = isEnabled
		self.isSelected = isSelected
		self.isHighlighted = isHighlighted
	}
}

public extension ViewStyle where View: Button {

	static func controlState(_ effect: @escaping (Button, Property<ControlState>) -> Void) -> ViewStyle {
		Self { button in
			let state = MutableProperty(ControlState(
				isEnabled: button.isEnabled,
				isSelected: button.isSelected,
				isHighlighted: button.isHighlighted
			))
			button.isEnabledDidSet = { state.value.isEnabled = $0 }
			button.isSelectedDidSet = { state.value.isSelected = $0 }
			button.isHighlightedDidSet = { state.value.isHighlighted = $0 }
			effect(button, state.readonly)
		}
	}

	static func highlighted(_ effect: @escaping (Button, Property<Bool>) -> Void) -> ViewStyle {
		controlState { button, state in effect(button, state.map(\.isHighlighted)) }
	}

	static func highlightedContent(insets: UIEdgeInsets = .zero, _ makeView: @escaping (Property<Bool>) -> UIView) -> ViewStyle {
		.highlighted { button, isHighlighted in
			let view = makeView(isHighlighted).applyingStyle(.assigning(\.isUserInteractionEnabled, to: false))
			button.pinSubview(view, insets: insets)
		}
	}

	static func highlightedBackground(normal: UIColor, highlighted: (UIColor) -> UIColor = \.darker) -> ViewStyle {
		.highlighted { [highlighted = highlighted(normal)] button, isHighlighted in
			button.bind(\.backgroundColor, to: isHighlighted.map { $0 ? highlighted : normal })
		}
	}

	static func highlightedTintColor(normal: UIColor, highlighted: UIColor) -> ViewStyle {
		.highlighted { button, isHighlighted in
			button.bind(\.tintColor, to: isHighlighted.map { $0 ? highlighted : normal })
		}
	}

//	static func defaultPillShape(title: Property<String>, titleColor: UIColor, backgroundColor: UIColor) -> ViewStyle {
//		∑[
//			.pill(height: .defaultButtonHeight),
//			.shadow(.high),
//			.highlightedBackground(normal: backgroundColor),
//			.content(insets: .horizontal(32), .line(
//				text: title,
//				style: ∑[
//					.font(.graphikMedium),
//					.size(.m),
//					.color(titleColor),
//					.alignment(.center)
//				],
//				labelStyle: .assigning(\.adjustsFontSizeToFitWidth, to: true)
//			))
//		]
//	}

//	static func defaultPillShape(title: String, titleColor: UIColor, backgroundColor: UIColor) -> ViewStyle {
//		defaultPillShape(title: const § title, titleColor: titleColor, backgroundColor: backgroundColor)
//	}
}

public extension ViewStyle where View: UILabel {
	static func multiline(lines: Int = 0) -> ViewStyle {
		.assigning(\.numberOfLines, to: lines)
	}
}

public extension ViewStyle where View: UIActivityIndicatorView {
	static func animating() -> Self {
		.init { view in
			view.startAnimating()
		}
	}
}

public extension CGFloat {
	static let defaultButtonHeight = 56 as CGFloat
}
