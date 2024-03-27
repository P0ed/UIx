import UIKit
import Fx

open class OverlayView: UIView {
	open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		super.hitTest(point, with: event).flatMap { $0 === self ? nil : $0 }
	}
}

public extension UITraitCollection {
	@objc var isDarkStyle: Bool { userInterfaceStyle == .dark }
}

public final class HitTestView: UIView {
	public typealias SuperHitTest = (CGPoint, UIEvent?) -> UIView?
	private let test: (HitTestView, CGPoint, UIEvent?, SuperHitTest) -> UIView?

	public required init?(coder: NSCoder) { fatalError() }

	public init(test: @escaping (HitTestView, CGPoint, UIEvent?, SuperHitTest) -> UIView?, subview: UIView? = nil) {
		self.test = test
		super.init(frame: subview.map { .size($0.bounds.size) } ?? .zero)
		if let subview = subview { pinSubview(subview) }
	}

	public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		test(self, point, event, { point, event in super.hitTest(point, with: event) })
	}
}

public extension HitTestView {

	convenience init(test: @escaping (HitTestView, CGPoint, UIEvent?) -> UIView?, subview: UIView? = nil) {
		self.init(
			test: { view, point, event, callSuper in
				test(view, point, event) ?? callSuper(point, event)
			},
			subview: subview
		)
	}

	convenience init(testing views: [UIView], subview: UIView) {
		self.init(
			test: { `self`, point, event in
				views.first { $0.point(inside: $0.convert(point, from: self), with: event) }
			},
			subview: subview
		)
	}

	convenience init(testing views: @escaping () -> [UIView], subview: UIView) {
		self.init(
			test: { `self`, point, event in
				views().first { $0.point(inside: $0.convert(point, from: self), with: event) }
			},
			subview: subview
		)
	}

	convenience init(ignoringStackViews subview: UIView?) {
		self.init(
			test: { view, point, event, callSuper in
				callSuper(point, event).flatMap { $0 is UIStackView ? nil : $0 }
			},
			subview: subview
		)
	}
}

public extension UIView {

	static func childController(_ controller: UIViewController) -> UIView {
		ChildControllerWrapper(controller)
	}

	private final class ChildControllerWrapper: UIView {
		private let controller: UIViewController
		private var didMove = {}

		init(_ controller: UIViewController) {
			self.controller = controller
			super.init(frame: .zero)
			pinSubview(controller.view)
		}

		required init?(coder: NSCoder) { fatalError() }

		override func willMove(toWindow newWindow: UIWindow?) {
			super.willMove(toWindow: newWindow)

			if newWindow != nil {
				if controller.parent == nil {
					didMove = { [weak self, controller] in
						if let parent = self?.findResponder(UIViewController.self) {
							parent.addChild(controller)
							controller.didMove(toParent: parent)
						}
					}
				}
			} else if controller.parent != nil {
				controller.willMove(toParent: nil)
				didMove = controller.removeFromParent
			}
		}

		override func didMoveToWindow() {
			super.didMoveToWindow()
			didMove()
			didMove = {}
		}
	}
}

public extension UIView {

	static func withWindow(_ makeView: (Property<UIWindow?>) -> UIView) -> UIView {
		let view = WindowDetector()
		view.pinSubview(makeView(view.$observableWindow))
		return view
	}

	static func withController(_ makeView: (Property<UIViewController?>) -> UIView) -> UIView {
		let view = WindowDetector()
		view.pinSubview(makeView(view.$observableWindow.map { [weak view] _ in view?.findResponder() }))
		return view
	}

	private final class WindowDetector: UIView {
		@MutableProperty private(set) var observableWindow: UIWindow?
		public override func didMoveToWindow() { observableWindow = window }
	}
}

public extension CALayer {
	/// Allows to pause and resume arbitrary animations
	var isPaused: Bool {
		get { speed == 0 }
		set {
			// Order matters:
			if newValue {
				let time = convertTime(CACurrentMediaTime(), from: nil)
				speed = 0
				timeOffset = time
			} else {
				let offset = timeOffset
				speed = 1
				timeOffset = 0
				beginTime = 0
				beginTime = convertTime(CACurrentMediaTime(), from: nil) - offset
			}
		}
	}
}
