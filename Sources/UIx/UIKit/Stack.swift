import UIKit

@MainActor
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

@MainActor
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

@MainActor
public func HStack(_ views: [UIView]) -> UIStackView { HStack(views: views) }
@MainActor
public func VStack(_ views: [UIView]) -> UIStackView { VStack(views: views) }

@MainActor
public func ZStack(_ views: [UIView]) -> UIView {
	views.reduce(into: UIView()) { $0.pinSubview($1) }
}

@MainActor
public func HStack(
	distribution: UIStackView.Distribution = .fill,
	alignment: UIStackView.Alignment = .fill,
	spacing: CGFloat = 0
) -> ([UIView]) -> UIStackView {
	{ HStack(distribution: distribution, alignment: alignment, spacing: spacing, views: $0) }
}

@MainActor
public func VStack(
	distribution: UIStackView.Distribution = .fill,
	alignment: UIStackView.Alignment = .fill,
	spacing: CGFloat = 0
) -> ([UIView]) -> UIStackView {
	{ VStack(distribution: distribution, alignment: alignment, spacing: spacing, views: $0) }
}

// TODO: Replace this with builder functions
@MainActor
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

@MainActor
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
	@MainActor
	func joined(separator: @autoclosure () -> UIView) -> [UIView] {
		reduce(into: []) { r, e in r += r.isEmpty ? [e] : [separator(), e] }
	}
}
