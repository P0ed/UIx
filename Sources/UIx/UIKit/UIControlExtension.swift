import UIKit
import Fx

@MainActor
private let kAssociatedActionsKey = UnsafeMutablePointer<Int8>.allocate(capacity: 1)

@MainActor
public protocol ControlActionFunctionProtocol {}

extension UIControl: ControlActionFunctionProtocol {}

public extension ControlActionFunctionProtocol where Self: UIControl {

	func setAction(_ events: UIControl.Event, _ action: ((Self) -> Void)?) {
		setActionWithEvent(events, action.map { action in
			{ control, _ in action(control) }
		})
	}

	func setActionWithEvent(_ events: UIControl.Event, _ action: ((Self, UIEvent) -> Void)?) {
		removeTarget(nil, action: nil, for: events)

		if let action = action {
			let trampoline = ControlActionTrampoline(action)
			addTarget(trampoline, action: trampoline.selector, for: events)
			actionsContainer.setAction(trampoline, forEvents: events)
		}
		else {
			actionsContainer.setAction(nil, forEvents: events)
		}
	}

	private var actionsContainer: ActionsContainer<Self> {
		if case .some(let container as ActionsContainer<Self>) = objc_getAssociatedObject(self, kAssociatedActionsKey) {
			return container
		} else {
			let container: ActionsContainer<Self> = ActionsContainer()
			objc_setAssociatedObject(self, kAssociatedActionsKey, container, .OBJC_ASSOCIATION_RETAIN)
			return container
		}
	}
}

public extension ControlActionFunctionProtocol where Self: UIButton {

	func setButtonAction(_ action: ((Self) -> Void)?) {
		setAction(.touchUpInside, action)
	}

	func setImage(state: UIControl.State = .normal, image: Property<UIImage?>) {
		apply(image) { button, image in
			button.setImage(image, for: state)
		}
	}
}

private final class ActionsContainer<Control> {
	private var actionsMap: [UInt: ControlActionTrampoline<Control>] = [:]

	func setAction(_ action: ControlActionTrampoline<Control>?, forEvents events: UIControl.Event) {

		let bits = UInt(MemoryLayout<Int>.size) * 8
		for i in 0..<bits where events.rawValue & 1 << i != 0 {
			actionsMap[1 << i] = action
		}
	}
}
