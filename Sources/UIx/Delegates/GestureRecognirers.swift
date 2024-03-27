import UIKit
import Fx

public protocol GestureRecognizerProtocol {}
extension UIGestureRecognizer: GestureRecognizerProtocol {}

public extension GestureRecognizerProtocol where Self: UIGestureRecognizer {

	init(handler: @escaping Sink<Self>) {
		self.init(handler: handler, setupDelegate: sink)
	}

	init(handler: @escaping Sink<Self>, setupDelegate setup: Sink<GestureRecognizerDelegate<Self>>) {
		self.init(target: nil, action: nil)
		addHandler(handler)
		setupDelegate(setup)
	}

	@discardableResult
	func addHandler(_ handler: @escaping (Self) -> Void) -> ManualDisposable {
		let trampoline = ActionTrampoline<Self>(handler)
		let capture = lifetime.capture(trampoline)
		addTarget(trampoline, action: trampoline.selector)

		return ManualDisposable {
			self.removeTarget(trampoline, action: trampoline.selector)
			capture.dispose()
		}
	}

	@discardableResult
	func setDelegate(_ delegate: GestureRecognizerDelegate<Self>) -> ManualDisposable {
		self.delegate = delegate
		return lifetime.capture(delegate)
	}

	@discardableResult
	func setupDelegate(_ setup: (GestureRecognizerDelegate<Self>) -> Void) -> ManualDisposable {
		let delegate = GestureRecognizerDelegate<Self>()
		setup(delegate)
		return setDelegate(delegate)
	}
}

public final class GestureRecognizerDelegate<ConcreteRecognizer: UIGestureRecognizer>: NSObject, UIGestureRecognizerDelegate {
	public var shouldBeRequiredToFailBy: ((ConcreteRecognizer, UIGestureRecognizer) -> Bool)?
	public var shouldRequireFailureOf: ((ConcreteRecognizer, UIGestureRecognizer) -> Bool)?
	public var shouldRecognizeSimultaneouslyWith: ((ConcreteRecognizer, UIGestureRecognizer) -> Bool)?
	public var shouldBegin: ((ConcreteRecognizer) -> Bool)?
	public var shouldReceiveTouch: ((ConcreteRecognizer, UITouch) -> Bool)?

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let recognizer = gestureRecognizer as? ConcreteRecognizer, let shouldBeRequiredToFailBy = shouldBeRequiredToFailBy else { return false }
		return shouldBeRequiredToFailBy(recognizer, otherGestureRecognizer)
	}
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let recognizer = gestureRecognizer as? ConcreteRecognizer, let shouldRequireFailureOf = shouldRequireFailureOf else { return false }
		return shouldRequireFailureOf(recognizer, otherGestureRecognizer)
	}
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let recognizer = gestureRecognizer as? ConcreteRecognizer, let shouldRecognizeSimultaneouslyWith = shouldRecognizeSimultaneouslyWith else { return false }
		return shouldRecognizeSimultaneouslyWith(recognizer, otherGestureRecognizer)
	}
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let recognizer = gestureRecognizer as? ConcreteRecognizer, let shouldBegin = shouldBegin else { return true }
		return shouldBegin(recognizer)
	}
	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		guard let recognizer = gestureRecognizer as? ConcreteRecognizer, let shouldReceiveTouch = shouldReceiveTouch else { return true }
		return shouldReceiveTouch(recognizer, touch)
	}
}

import UIKit.UIGestureRecognizerSubclass

public final class TouchGestureRecognizer: UIGestureRecognizer {
	private let moveThreshold = 10 as CGFloat
	private var touchLocation = nil as CGPoint?

	public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		if state == .possible { state = .began }
		touchLocation = touches.first?.location(in: view)
	}
	public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		guard let initial = touchLocation, let to = touches.first?.location(in: view),
		   max(abs(to.x - initial.x), abs(to.y - initial.y)) > moveThreshold
		else { return }
		state = .failed
	}
	public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
		state = .recognized
	}
	public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
		state = .cancelled
	}
}
