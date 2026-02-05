import UIKit
import Fx

public extension UIView {

	@discardableResult
	func pinSubview(
		_ view: UIView,
		insertAt idx: Int? = nil,
		edges: UIRectEdge = .all,
		insets: UIEdgeInsets = .zero,
		priority: UILayoutPriority = .required,
		guide: UILayoutGuide? = nil
	) -> EdgeConstraints {
		if let idx {
			insertSubview(view, at: idx)
		} else {
			addSubview(view)
		}
		return view.pin(to: guide ?? self, edges: edges, insets: insets, priority: priority)
	}
}

public extension UIStackView {
	
	convenience init(
		axis: NSLayoutConstraint.Axis = .horizontal,
		distribution: UIStackView.Distribution = .fill,
		alignment: UIStackView.Alignment = .fill,
		spacing: CGFloat = 0,
		views: [UIView] = []
	) {
		self.init(arrangedSubviews: views)
		self.axis = axis
		self.distribution = distribution
		self.alignment = alignment
		self.spacing = spacing
	}
}

public extension UIView {

	convenience init(
		edges: UIRectEdge = .all,
		insets: UIEdgeInsets = .zero,
		priority: UILayoutPriority = .required,
		guide: KeyPath<UIView, UILayoutGuide>? = nil,
		subview: UIView
	) {
		self.init(frame: .size(subview.bounds.size))
		pinSubview(subview, edges: edges, insets: insets, priority: priority, guide: guide.map { self[keyPath: $0] })
	}
}

@MainActor
public protocol LayoutBox where Self: NSObject {
	var leadingAnchor: NSLayoutXAxisAnchor { get }
	var trailingAnchor: NSLayoutXAxisAnchor { get }
	var leftAnchor: NSLayoutXAxisAnchor { get }
	var rightAnchor: NSLayoutXAxisAnchor { get }
	var topAnchor: NSLayoutYAxisAnchor { get }
	var bottomAnchor: NSLayoutYAxisAnchor { get }
	var widthAnchor: NSLayoutDimension { get }
	var heightAnchor: NSLayoutDimension { get }
	var centerXAnchor: NSLayoutXAxisAnchor { get }
	var centerYAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: LayoutBox {}
extension UILayoutGuide: LayoutBox {}

@MainActor
public struct EdgeConstraints {
	public var top: NSLayoutConstraint?
	public var left: NSLayoutConstraint?
	public var bottom: NSLayoutConstraint?
	public var right: NSLayoutConstraint?
}

public extension EdgeConstraints {
	func setInsets(_ insets: UIEdgeInsets) {
		top?.constant = insets.top
		left?.constant = insets.left
		bottom?.constant = -insets.bottom
		right?.constant = -insets.right
	}
}

@MainActor
public struct SizeConstraints {
	public var width: NSLayoutConstraint
	public var height: NSLayoutConstraint
}

public extension LayoutBox {

	private func disableAutoresizingMaskContstraints() {
		(self as? UIView)?.translatesAutoresizingMaskIntoConstraints = false
	}

	@discardableResult
	func pin(to box: LayoutBox, edges: UIRectEdge = .all, insets: UIEdgeInsets = .zero, priority: UILayoutPriority = .required) -> EdgeConstraints {
		disableAutoresizingMaskContstraints()
		let top = edges.contains(.top) ? topAnchor.constraint(equalTo: box.topAnchor, constant: insets.top) : nil
		let left = edges.contains(.left) ? leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: insets.left) : nil
		let bottom = edges.contains(.bottom) ? bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -insets.bottom) : nil
		let right = edges.contains(.right) ? trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -insets.right) : nil

		let constraints = [top, left, bottom, right].compactMap(id)
		constraints.forEach { $0.priority = priority }
		NSLayoutConstraint.activate(constraints)

		return EdgeConstraints(top: top, left: left, bottom: bottom, right: right)
	}

	func pinCenter(to box: LayoutBox, priority: UILayoutPriority = .required) {
		disableAutoresizingMaskContstraints()
		let x = centerXAnchor.constraint(equalTo: box.centerXAnchor)
		let y = centerYAnchor.constraint(equalTo: box.centerYAnchor)

		let constraints = [x, y]
		constraints.forEach { $0.priority = priority }

		NSLayoutConstraint.activate(constraints)
	}

	@discardableResult
	private func align<Axis>(anchor: NSLayoutAnchor<Axis>, to secondAnchor: NSLayoutAnchor<Axis>, offset: CGFloat, priority: UILayoutPriority) -> NSLayoutConstraint {
		let constraint = anchor.constraint(equalTo: secondAnchor, constant: offset)
		constraint.priority = priority
		constraint.isActive = true
		return constraint
	}

	@discardableResult
	func align(_ keyPath: KeyPath<Self, NSLayoutXAxisAnchor>, to anchor: NSLayoutXAxisAnchor, offset: CGFloat = 0, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
		align(anchor: self[keyPath: keyPath], to: anchor, offset: offset, priority: priority)
	}

	@discardableResult
	func align(_ keyPath: KeyPath<Self, NSLayoutYAxisAnchor>, to anchor: NSLayoutYAxisAnchor, offset: CGFloat = 0, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
		align(anchor: self[keyPath: keyPath], to: anchor, offset: offset, priority: priority)
	}

	@discardableResult
	func matchSize(to box: LayoutBox) -> SizeConstraints {
		disableAutoresizingMaskContstraints()
		let width = widthAnchor.constraint(equalTo: box.widthAnchor)
		let height = heightAnchor.constraint(equalTo: box.heightAnchor)
		NSLayoutConstraint.activate([width, height])
		return SizeConstraints(width: width, height: height)
	}

	@discardableResult
	func matchWidth(to box: LayoutBox, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
		disableAutoresizingMaskContstraints()
		let constraint = widthAnchor.constraint(equalTo: box.widthAnchor)
		constraint.priority = priority
		constraint.isActive = true
		return constraint
	}

	@discardableResult
	func matchHeight(to box: LayoutBox, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
		disableAutoresizingMaskContstraints()
		let constraint = heightAnchor.constraint(equalTo: box.heightAnchor)
		constraint.priority = priority
		constraint.isActive = true
		return constraint
	}

	@discardableResult
	func matchSize(to size: CGSize) -> SizeConstraints {
		disableAutoresizingMaskContstraints()
		let width = widthAnchor.constraint(equalToConstant: size.width)
		let height = heightAnchor.constraint(equalToConstant: size.height)
		NSLayoutConstraint.activate([width, height])
		return SizeConstraints(width: width, height: height)
	}

	@discardableResult
	func matchWidth(to width: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
		disableAutoresizingMaskContstraints()
		let constraint: NSLayoutConstraint = {
			switch relation {
			case .equal: return widthAnchor.constraint(equalToConstant: width)
			case .lessThanOrEqual: return widthAnchor.constraint(lessThanOrEqualToConstant: width)
			case .greaterThanOrEqual: return widthAnchor.constraint(greaterThanOrEqualToConstant: width)
			@unknown default: fatalError()
			}
		}()
		constraint.priority = priority
		constraint.isActive = true
		return constraint
	}

	@discardableResult
	func matchHeight(to height: CGFloat, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
		disableAutoresizingMaskContstraints()
		let constraint: NSLayoutConstraint = {
			switch relation {
			case .equal: return heightAnchor.constraint(equalToConstant: height)
			case .lessThanOrEqual: return heightAnchor.constraint(lessThanOrEqualToConstant: height)
			case .greaterThanOrEqual: return heightAnchor.constraint(greaterThanOrEqualToConstant: height)
			@unknown default: fatalError()
			}
		}()
		constraint.priority = priority
		constraint.isActive = true
		return constraint
	}

	@discardableResult
	func matchWidth(to width: Property<CGFloat>, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
		disableAutoresizingMaskContstraints()
		let constraint: NSLayoutConstraint = {
			switch relation {
			case .equal: return widthAnchor.constraint(equalToConstant: width.value)
			case .lessThanOrEqual: return widthAnchor.constraint(lessThanOrEqualToConstant: width.value)
			case .greaterThanOrEqual: return widthAnchor.constraint(greaterThanOrEqualToConstant: width.value)
			@unknown default: fatalError()
			}
		}()
		constraint.priority = priority
		constraint.isActive = true
		lifetime += width.signal.observe { constraint.constant = $0 }
		return constraint
	}

	@discardableResult
	func matchHeight(to height: Property<CGFloat>, relation: NSLayoutConstraint.Relation = .equal, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
		disableAutoresizingMaskContstraints()
		let constraint: NSLayoutConstraint = {
			switch relation {
			case .equal: return heightAnchor.constraint(equalToConstant: height.value)
			case .lessThanOrEqual: return heightAnchor.constraint(lessThanOrEqualToConstant: height.value)
			case .greaterThanOrEqual: return heightAnchor.constraint(greaterThanOrEqualToConstant: height.value)
			@unknown default: fatalError()
			}
		}()
		constraint.priority = priority
		constraint.isActive = true
		lifetime += height.signal.observe { constraint.constant = $0 }
		return constraint
	}
}

public final class LayoutView: UIView {
	@MutableProperty
	public private(set) var size: CGSize = .zero

	public init(layout: ((CGSize) -> Void)? = nil) {
		super.init(frame: .zero)
		if let layout = layout {
			lifetime += _size.observe(layout)
		}
	}

	public init(_ makeView: (Property<CGSize>) -> UIView) {
		super.init(frame: .zero)
		pinSubview(makeView($size))
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		size = bounds.size
	}
}

public final class TraitsView: UIView {
	@MutableProperty
	public private(set) var traits: UITraitCollection = .init()

	public init(_ makeView: ((Property<UITraitCollection>) -> UIView)? = nil) {
		super.init(frame: .zero)
		traits = traitCollection

		if let contentView = makeView?($traits) {
			pinSubview(contentView)
		}
	}

	public required init?(coder: NSCoder) { fatalError() }

	public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		traits = traitCollection
	}
}

public final class SafeAreaView: UIView {
	@MutableProperty
	public private(set) var insets: UIEdgeInsets = .zero

	public override func safeAreaInsetsDidChange() {
		insets = safeAreaInsets
	}
}

public final class LayerView<Layer: CALayer>: UIView {
	public override static var layerClass: AnyClass { Layer.self }
	public var typedLayer: Layer { layer as! Layer }
}

public extension UIEdgeInsets {
	static func top(_ x: CGFloat) -> UIEdgeInsets { UIEdgeInsets(top: x, left: 0, bottom: 0, right: 0) }
	static func left(_ x: CGFloat) -> UIEdgeInsets { UIEdgeInsets(top: 0, left: x, bottom: 0, right: 0) }
	static func bottom(_ x: CGFloat) -> UIEdgeInsets { UIEdgeInsets(top: 0, left: 0, bottom: x, right: 0) }
	static func right(_ x: CGFloat) -> UIEdgeInsets { UIEdgeInsets(top: 0, left: 0, bottom: 0, right: x) }
	static func horizontal(_ x: CGFloat) -> UIEdgeInsets { UIEdgeInsets(top: 0, left: x, bottom: 0, right: x) }
	static func vertical(_ x: CGFloat) -> UIEdgeInsets { UIEdgeInsets(top: x, left: 0, bottom: x, right: 0) }
	static func all(_ x: CGFloat) -> UIEdgeInsets { UIEdgeInsets(top: x, left: x, bottom: x, right: x) }

	static func create(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> UIEdgeInsets {
		UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
	}
	static func create(vertical: CGFloat = 0, horizontal: CGFloat = 0) -> UIEdgeInsets {
		UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
	}
	static func create(all value: CGFloat) -> UIEdgeInsets {
		UIEdgeInsets(top: value, left: value, bottom: value, right: value)
	}

	var horizontal: CGFloat { left + right }
	var vertical: CGFloat { top + bottom }
}

extension UIEdgeInsets: @retroactive Semigroup {
	public mutating func combine(_ x: UIEdgeInsets) {
		top += x.top
		left += x.left
		bottom += x.bottom
		right += x.right
	}
}

extension UIEdgeInsets: @retroactive Monoid {
	public static let empty: UIEdgeInsets = .zero
}

public extension CGRect {

	static func size(_ size: CGSize) -> CGRect { CGRect(origin: .zero, size: size) }

	var center: CGPoint { CGPoint(x: midX, y: midY) }
}

public extension CGSize {

	static func square(_ side: CGFloat) -> CGSize { CGSize(width: side, height: side) }
	static func width(_ width: CGFloat) -> CGSize { CGSize(width: width, height: 0) }
	static func height(_ height: CGFloat) -> CGSize { CGSize(width: 0, height: height) }

	var center: CGPoint { CGPoint(x: width / 2, y: height / 2) }
	var ratio: CGFloat { width / height }

	func inset(_ insets: UIEdgeInsets) -> CGSize {
		CGSize(width: width - insets.horizontal, height: height - insets.vertical)
	}

	func offset(_ offset: UIEdgeInsets) -> CGSize {
		CGSize(width: width + offset.horizontal, height: height + offset.vertical)
	}

	func fittingSize(_ size: CGSize) -> CGSize {
		let ratio = min(width / size.width, height / size.height)
		return CGSize(width: (size.width * ratio).rounded(), height: (size.height * ratio).rounded())
	}
}

public extension CGPoint {
	static func x(_ value: CGFloat) -> CGPoint { CGPoint(x: value, y: 0) }
	static func y(_ value: CGFloat) -> CGPoint { CGPoint(x: 0, y: value) }
}

public extension UIRectEdge {
	static func except(_ edge: UIRectEdge) -> UIRectEdge { UIRectEdge.all.subtracting(edge) }
}

public extension UILayoutPriority {
	var lower: UILayoutPriority { UILayoutPriority(rawValue - 1) }
	var higher: UILayoutPriority { UILayoutPriority(rawValue + 1) }
	static let zero = UILayoutPriority(0)
	static let collectionRequired = UILayoutPriority.required.lower
}

public extension UIRectEdge {
	static var horizontal: UIRectEdge { [.left, .right] }
	static var vertical: UIRectEdge { [.top, .bottom] }
	static var none: UIRectEdge { [] }
}

public extension CGPoint {
	static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
		CGPoint(
			x: lhs.x - rhs.x,
			y: lhs.y - rhs.y
		)
	}
}
