import Fx
import Foundation

public struct Task<A: Sendable>: Sendable {
	public let result: Promise<A>
	public let cancel: ManualDisposable

	public init(result: Promise<A>, cancel: ManualDisposable) {
		self.result = result
		self.cancel = cancel
	}
}

public extension Task {

	static func result(_ result: Promise<A>) -> Task {
		Task(result: result, cancel: ManualDisposable(action: {}))
	}

	func map<B: Sendable>(_ f: @isolated(any) @Sendable @escaping (A) throws -> B) -> Task<B> {
		Task<B>(result: result.map(f), cancel: cancel)
	}

	func flatMap<B: Sendable>(_ f: @isolated(any) @Sendable @escaping (A) throws -> Task<B>) -> Task<B> {
		let cancelNext = Atomic<ManualDisposable?>(nil)
		return Task<B>(
			result: result.isolatedFlatMap { x in
				do {
					let next = try await f(x)
					cancelNext.value = next.cancel
					return next.result
				}
				catch {
					return Promise(error: error)
				}
			},
			cancel: ManualDisposable { [cancel] in
				cancel.dispose()
				cancelNext.value?.dispose()
			}
		)
	}

	func recover(_ f: @escaping (Error) throws -> Task<A>) -> Task<A> {
		let cancelNext = Atomic<ManualDisposable?>(nil)
		let isCancelled = Atomic<Bool>(false)
		return Task<A>(
			result: result.flatMapError { (e) -> Promise<A> in
				isCancelled.withValue { isCancelled in
					if isCancelled {
						return Promise(error: e)
					}
					do {
						let next = try f(e)
						cancelNext.value = next.cancel
						return next.result
					}
					catch {
						return Promise(error: error)
					}
				}
			},
			cancel: ManualDisposable { [cancel] in
				isCancelled.value = true
				cancel.dispose()
				cancelNext.value?.dispose()
			}
		)
	}

	func onComplete(_ f: @isolated(any) @Sendable @escaping (Result<A, Error>) -> Void) -> ManualDisposable {
		result.onComplete(f)
		return cancel
	}
}

public extension OperationQueue {

	func addTask<A>(priority: Operation.QueuePriority = .normal, generator: @escaping () -> Task<A>) -> Task<A> {
		let operation = AsyncOperation(generator: generator)
		operation.queuePriority = priority
		addOperation(operation)
		return Task<A>(
			result: operation.result,
			cancel: ManualDisposable(action: operation.cancel)
		)
	}

	@discardableResult
	func promise<A>(priority: Operation.QueuePriority, _ generator: @escaping () -> Promise<A>) -> Promise<A> {
		addTask(priority: priority, generator: Task.result • generator).result
	}

	@discardableResult
	func promise<A>(_ generator: @escaping () -> Promise<A>) -> Promise<A> {
		promise(priority: .normal, generator)
	}
}
