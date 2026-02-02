import UIKit
import Fx

public extension ViewStyle where View: UITextField {
	static func setupDelegate(_ setup: @escaping (TextFieldDelegate) -> Void) -> ViewStyle {
		ViewStyle {
			let delegate = TextFieldDelegate()
			$0.lifetime.capture(delegate)
			$0.delegate = delegate
			setup(delegate)
		}
	}
}

public extension UITextField {

	var observableText: Property<String> {
		let nc = NotificationCenter.default
		let name = UITextField.textDidChangeNotification
		let textDidChange = nc.signal(forName: name, object: self)
			.map { ($0.object as? UITextField)?.text ?? "" }

		return Property(value: text ?? "", signal: textDidChange)
	}
}

public final class TextFieldDelegate: NSObject, UITextFieldDelegate {
	public var shouldBeginEditing: (UITextField) -> Bool = { _ in true }
	public var didBeginEditing: (UITextField) -> Void = { _ in }
	public var didEndEditing: (UITextField) -> Void = { _ in }
	public var shouldReturn: (UITextField) -> Bool = { _ in true }
	public var shouldChangeCharactersInRange: (UITextField, NSRange, String) -> Bool = { _, _, _ in true }

	public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		shouldBeginEditing(textField)
	}

	public func textFieldDidBeginEditing(_ textField: UITextField) {
		didBeginEditing(textField)
	}

	public func textFieldDidEndEditing(_ textField: UITextField) {
		didEndEditing(textField)
	}

	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		shouldReturn(textField)
	}

	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		shouldChangeCharactersInRange(textField, range, string)
	}
}
