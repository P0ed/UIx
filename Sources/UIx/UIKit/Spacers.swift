import UIKit
import Fx

public final class Spacer: UIView {
	public let size: CGSize
	public init(size: CGSize) {
		self.size = size
		super.init(frame: .size(size))
		setContentHuggingPriority(.required, for: .horizontal)
		setContentHuggingPriority(.required, for: .vertical)
		setContentCompressionResistancePriority(.required, for: .horizontal)
		setContentCompressionResistancePriority(.required, for: .vertical)
	}
	public required init?(coder aDecoder: NSCoder) { fatalError() }
	public override var intrinsicContentSize: CGSize { size }
}

public final class DynamicSpacer: UIView {
	public private(set) var size: CGSize { didSet { invalidateIntrinsicContentSize() } }
	public init(size: Property<CGSize>) {
		self.size = size.value
		super.init(frame: .size(size.value))
		setContentHuggingPriority(.required, for: .horizontal)
		setContentHuggingPriority(.required, for: .vertical)
		setContentCompressionResistancePriority(.required, for: .horizontal)
		setContentCompressionResistancePriority(.required, for: .vertical)
		bind(\.size, to: size)
	}
	public required init?(coder aDecoder: NSCoder) { fatalError() }
	public override var intrinsicContentSize: CGSize { size }
}

@MainActor
public func HSpacer(_ width: CGFloat) -> UIView {
	Spacer(size: CGSize(width: width, height: UIView.noIntrinsicMetric))
}
@MainActor
public func VSpacer(_ height: CGFloat) -> UIView {
	Spacer(size: CGSize(width: UIView.noIntrinsicMetric, height: height))
}
@MainActor
public func HSpacer(_ width: Property<CGFloat>) -> UIView {
	DynamicSpacer(size: width.map { CGSize(width: $0, height: UIView.noIntrinsicMetric) })
}
@MainActor
public func VSpacer(_ height: Property<CGFloat>) -> UIView {
	DynamicSpacer(size: height.map { CGSize(width: UIView.noIntrinsicMetric, height: $0) })
}

public final class FlexibleSpacer: UIView {
	public override init(frame: CGRect) {
		super.init(frame: frame)
		translatesAutoresizingMaskIntoConstraints = false
		setContentHuggingPriority(.zero, for: .horizontal)
		setContentHuggingPriority(.zero, for: .vertical)
		setContentCompressionResistancePriority(.zero, for: .horizontal)
		setContentCompressionResistancePriority(.zero, for: .vertical)
	}
	public required init?(coder: NSCoder) { fatalError() }
	public override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric) }
}
