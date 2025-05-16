import Fx
import Foundation

public struct AsyncTask<A: Sendable>: Sendable {
	public let result: Promise<A>
	public let cancel: ManualDisposable

	public init(result: Promise<A>, cancel: ManualDisposable) {
		self.result = result
		self.cancel = cancel
	}
}

public extension AsyncTask {

	static func result(_ result: Promise<A>) -> AsyncTask {
		AsyncTask(result: result, cancel: ManualDisposable(action: {}))
	}

	func map<B: Sendable>(_ f: @isolated(any) @Sendable @escaping (A) throws -> B) -> AsyncTask<B> {
		AsyncTask<B>(result: result.map(f), cancel: cancel)
	}

	func flatMap<B: Sendable>(_ f: @isolated(any) @Sendable @escaping (A) throws -> AsyncTask<B>) -> AsyncTask<B> {
		let cancelNext = Atomic<ManualDisposable?>(nil)
		return AsyncTask<B>(
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

	func recover(_ f: @escaping (Error) throws -> AsyncTask<A>) -> AsyncTask<A> {
		let cancelNext = Atomic<ManualDisposable?>(nil)
		let isCancelled = Atomic<Bool>(false)
		return AsyncTask<A>(
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

	func addTask<A>(priority: Operation.QueuePriority = .normal, generator: @escaping () -> AsyncTask<A>) -> AsyncTask<A> {
		let operation = AsyncOperation(generator: generator)
		operation.queuePriority = priority
		addOperation(operation)
		return AsyncTask<A>(
			result: operation.result,
			cancel: ManualDisposable(action: operation.cancel)
		)
	}

	@discardableResult
	func promise<A: Sendable>(priority: Operation.QueuePriority, _ generator: @escaping () -> Promise<A>) -> Promise<A> {
		addTask(priority: priority, generator: AsyncTask.result • generator).result
	}

	@discardableResult
	func promise<A: Sendable>(_ generator: @escaping () -> Promise<A>) -> Promise<A> {
		promise(priority: .normal, generator)
	}
}
