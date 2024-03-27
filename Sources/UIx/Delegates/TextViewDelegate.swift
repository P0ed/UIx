import UIKit
import Fx

public extension UITextView {

	convenience init(setupDelegate setup: Sink<TextViewDelegate>) {
		self.init()
		let delegate = TextViewDelegate()
		setup(delegate)
		setupDelegate(delegate)
	}

	@discardableResult
	func setupDelegate(_ delegate: TextViewDelegate) -> ManualDisposable {
		self.delegate = delegate
		return lifetime.capture(delegate)
	}
}

public final class TextViewDelegate: NSObject, UITextViewDelegate {

	public var shouldBeginEditing: ((UITextView) -> Bool)?
	public var shouldEndEditing: ((UITextView) -> Bool)?
	public var didBeginEditing: ((UITextView) -> Void)?
	public var didEndEditing: ((UITextView) -> Void)?
	public var shouldChangeTextInRangeWithReplacementText: ((UITextView, NSRange, String) -> Bool)?
	public var didChange: ((UITextView) -> Void)?
	public var didChangeSelection: ((UITextView) -> Void)?
	public var shouldInteractWithURLInCharacterRange: ((UITextView, URL, NSRange) -> Bool)?
	public var shouldInteractWithURLInCharacterRangeWithInteraction: ((UITextView, URL, NSRange, UITextItemInteraction) -> Bool)?
	public var shouldInteractWithTextAttachmentInCharacterRange: ((UITextView, NSTextAttachment, NSRange) -> Bool)?
	public var shouldInteractWithTextAttachmentInCharacterRangeWithInteraction: ((UITextView, NSTextAttachment, NSRange, UITextItemInteraction) -> Bool)?

	public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		shouldBeginEditing?(textView) ?? true
	}

	public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
		shouldEndEditing?(textView) ?? true
	}

	public func textViewDidBeginEditing(_ textView: UITextView) {
		didBeginEditing?(textView)
	}

	public func textViewDidEndEditing(_ textView: UITextView) {
		didEndEditing?(textView)
	}

	public func textView(
		_ textView: UITextView,
		shouldChangeTextIn range: NSRange,
		replacementText text: String
	) -> Bool {
		shouldChangeTextInRangeWithReplacementText?(textView, range, text) ?? true
	}

	public func textViewDidChange(_ textView: UITextView) {
		didChange?(textView)
	}

	public func textViewDidChangeSelection(_ textView: UITextView) {
		didChangeSelection?(textView)
	}

	public func textView(
		_ textView: UITextView,
		shouldInteractWith URL: URL,
		in characterRange: NSRange
	) -> Bool {
		shouldInteractWithURLInCharacterRange?(
			textView,
			URL,
			characterRange
		) ?? true
	}

	public func textView(
		_ textView: UITextView,
		shouldInteractWith URL: URL,
		in characterRange: NSRange,
		interaction: UITextItemInteraction
	) -> Bool {
		shouldInteractWithURLInCharacterRangeWithInteraction?(
			textView,
			URL,
			characterRange,
			interaction
		) ?? true
	}

	public func textView(
		_ textView: UITextView,
		shouldInteractWith textAttachment: NSTextAttachment,
		in characterRange: NSRange,
		interaction: UITextItemInteraction
	) -> Bool {
		shouldInteractWithTextAttachmentInCharacterRangeWithInteraction?(
			textView,
			textAttachment,
			characterRange,
			interaction
		) ?? true
	}

	public func textView(
		_ textView: UITextView,
		shouldInteractWith textAttachment: NSTextAttachment,
		in characterRange: NSRange
	) -> Bool {
		shouldInteractWithTextAttachmentInCharacterRange?(
			textView,
			textAttachment,
			characterRange
		) ?? true
	}
}
