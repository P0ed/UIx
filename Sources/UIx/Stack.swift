public func HStack(
	distribution: UIStackView.Distribution = .fill,
	alignment: UIStackView.Alignment = .fill,
	spacing: CGFloat = 0,
	views: [UIView]
) -> UIStackView {
	UIStackView(
		axis: .horizontal,
		distribution: distribution,
		alignment: alignment,
		spacing: spacing,
		views: views
	)
}

public func VStack(
	distribution: UIStackView.Distribution = .fill,
	alignment: UIStackView.Alignment = .fill,
	spacing: CGFloat = 0,
	views: [UIView]
) -> UIStackView {
	UIStackView(
		axis: .vertical,
		distribution: distribution,
		alignment: alignment,
		spacing: spacing,
		views: views
	)
}

public func HStack(_ views: [UIView]) -> UIStackView { HStack(views: views) }
public func VStack(_ views: [UIView]) -> UIStackView { VStack(views: views) }

public func ZStack(_ views: [UIView]) -> UIView {
	views.reduce(into: UIView()) { $0.pinSubview($1) }
}

public func HStack(
	distribution: UIStackView.Distribution = .fill,
	alignment: UIStackView.Alignment = .fill,
	spacing: CGFloat = 0
) -> ([UIView]) -> UIStackView {
	{ HStack(distribution: distribution, alignment: alignment, spacing: spacing, views: $0) }
}

public func VStack(
	distribution: UIStackView.Distribution = .fill,
	alignment: UIStackView.Alignment = .fill,
	spacing: CGFloat = 0
) -> ([UIView]) -> UIStackView {
	{ VStack(distribution: distribution, alignment: alignment, spacing: spacing, views: $0) }
}

// TODO: Replace this with builder functions
public func HStack(
	distribution: UIStackView.Distribution = .fill,
	alignment: UIStackView.Alignment = .fill,
	spacing: CGFloat = 0,
	_ views: [UIView]
) -> UIStackView {
	HStack(
		distribution: distribution,
		alignment: alignment,
		spacing: spacing,
		views: views
	)
}

public func VStack(
	distribution: UIStackView.Distribution = .fill,
	alignment: UIStackView.Alignment = .fill,
	spacing: CGFloat = 0,
	_ views: [UIView]
) -> UIStackView {
	VStack(
		distribution: distribution,
		alignment: alignment,
		spacing: spacing,
		views: views
	)
}

public extension Sequence where Element: UIView {

	func joined(separator: @autoclosure () -> UIView) -> [UIView] {
		reduce(into: []) { r, e in r += r.isEmpty ? [e] : [separator(), e] }
	}
}
