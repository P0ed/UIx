import Fx

public typealias LoadAction = AsyncAction<Void, Void>
public typealias LoadFunction = Function<Void, Promise<Void>>

public enum AsyncActionExecutionState { case idle, running, error(Error) }

public extension AsyncActionExecutionState {
	var isIdle: Bool { if case .idle = self { return true } else { return false } }
	var isRunning: Bool { if case .running = self { return true } else { return false } }
	var error: Error? { if case let .error(error) = self { return error } else { return nil } }
}

@propertyWrapper
public final class AsyncAction<I, O> {
	@Property public var isEnabled: Bool

	@MutableProperty public private(set) var running: Promise<O>?

	private let _run: (I) -> Promise<O>
	@discardableResult
	public func run(_ input: I) -> Promise<O> { _run(input) }

	public var wrappedValue: Function<I, Promise<O>> { Function(self.run) }
	public var projectedValue: AsyncAction<I, O> { self }

	private struct NotAvailable: Error {}
	public static func notAvailable(_ input: I) -> Promise<O> { .error(NotAvailable()) }

	/// Allows one task at a time, preventing any successive actions before running is complete.
	/// Specifying `const § .void` as the `disabled` function, `run` will behave the same as `runIfNeeded`
	public init(
		isEnabled: Property<Bool> = .const(true),
		disabled: @escaping (I) -> Promise<O> = notAvailable,
		action: @escaping (I) -> Promise<O>
	) {
		_isEnabled = isEnabled.and(_running.map(\.isNil))

		_run = { [_isEnabled, _running] input in
			guard _isEnabled.value else { return disabled(input) }

			let result = action(input).withResult { _ in
				_running.value = nil
			}
			_running.value = result
			return result
		}
	}

	/// Allows one task at a time by cancelling previously started action
	public init(
		isEnabled: Property<Bool> = .const(true),
		disabled: @escaping (I) -> Promise<O> = notAvailable,
		cancellableAction: @escaping (I) -> Task<O>
	) {
		_isEnabled = isEnabled

		_run = { [_isEnabled, _running, cancel = SerialDisposable()] input in
			guard _isEnabled.value else { return disabled(input) }

			let task = cancellableAction(input)
			cancel.innerDisposable = task.cancel
			var current = nil as Promise<O>?
			let result = task.result.withResult { _ in
				if _running.value === current {
					_running.value = nil
				}
			}
			current = result
			_running.value = result
			return result
		}
	}
}

public extension AsyncAction {
	var isRunning: Bool { running != nil }

	var executions: Signal<Promise<O>> { $running.signal.ignoringNils() }

	var executionState: Property<AsyncActionExecutionState> {
		Property(value: isRunning ? .running : .idle, signal: Signal { sink in
			var last = nil as Promise<O>?
			return $running.observe { running in
				guard let running = running else { return }
				last = running
				sink(.running)
				running.onComplete(.main) { [weak running] result in
					guard last === running else { return }
					sink(result.error.map(AsyncActionExecutionState.error) ?? .idle)
				}
			}
		})
	}

	func callAsFunction(_ input: I) -> Promise<O> { run(input) }
}

public extension AsyncAction where I == Void {
	@discardableResult
	func run() -> Promise<O> { run(()) }

	func callAsFunction() -> Promise<O> { run() }
}

public extension AsyncAction where I == Void, O == Void {

	/// Returns `.void` instead of an error if the action is not available at the moment
	@discardableResult
	func runIfNeeded() -> Promise<Void> {
		isEnabled ? run() : .void
	}

	static var empty: AsyncAction {
		AsyncAction(isEnabled: .const(false), action: { .void })
	}

	static func once(_ action: @escaping () -> Promise<Void>) -> AsyncAction {
		once(action • sink)
	}

	func chained(_ tail: AsyncAction) -> AsyncAction {
		AsyncAction(
			isEnabled: $isEnabled.or(tail.$isEnabled),
			action: { [self] _ in isEnabled ? runIfNeeded() : tail.runIfNeeded() }
		)
	}

	static func chained(_ actions: AsyncAction...) -> AsyncAction {
		actions.reduce(empty) { $0.chained($1) }
	}

	/// Page model's case where head is page load data action and tail is list section`s pagination
	static func page(head: AsyncAction, tail: AsyncAction) -> AsyncAction {
		AsyncAction(
			isEnabled: head.$isEnabled.or(tail.$isEnabled),
			action: { head.runIfNeeded().flatMap { tail.runIfNeeded() } }
		)
	}

	struct PaginationIn {
		public var page: Int
		public var perPage: Int?
	}
	struct PaginationOut {
		public var isEmpty: Bool

		public static func isEmpty(_ isEmpty: Bool) -> PaginationOut { Self(isEmpty: isEmpty) }
	}
	static func pagination(load: AsyncAction<PaginationIn, PaginationOut>) -> AsyncAction {
		var page = 1

		let isComplete = MutableProperty(false)

		return AsyncAction(
			isEnabled: isComplete.not,
			action: {
				load(PaginationIn(page: page)).map { out in
					page += 1
					if out.isEmpty { isComplete.value = true }
				}
			}
		)
	}
}

public extension AsyncAction {

	static func once(_ action: @escaping (I) -> Promise<O>) -> AsyncAction {
		let loaded = MutableProperty(false)
		return AsyncAction(
			isEnabled: loaded.not,
			action: { action($0).with(.main) { _ in loaded.value = true } }
		)
	}
}

public extension PropertyType where A == Bool {
	var not: Property<Bool> { map(!) }
	func and(_ other: Property<Bool>) -> Property<Bool> { flatMap { $0 ? other : .const(false) } }
	func or(_ other: Property<Bool>) -> Property<Bool> { flatMap { $0 ? .const(true) : other } }
}
