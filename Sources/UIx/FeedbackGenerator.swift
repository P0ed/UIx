import UIKit

public struct FeedbackGenerator<Input> {
	public var generate: (Input) -> Void
}

public extension FeedbackGenerator where Input == UINotificationFeedbackGenerator.FeedbackType {
	static func notification() -> FeedbackGenerator {
		FeedbackGenerator(generate: UINotificationFeedbackGenerator().notificationOccurred)
	}
}

public extension FeedbackGenerator where Input == Void {

	func trigger() { generate(()) }

	static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) -> FeedbackGenerator {
		FeedbackGenerator(generate: UIImpactFeedbackGenerator(style: style).impactOccurred)
	}
	static func selection() -> FeedbackGenerator {
		FeedbackGenerator(generate: UISelectionFeedbackGenerator().selectionChanged)
	}
}
