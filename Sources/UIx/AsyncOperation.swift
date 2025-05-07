import Foundation
import Fx

public final class AsyncOperation<A: Sendable>: Operation, @unchecked Sendable {

	public override var isAsynchronous: Bool { true }

	public override var isExecuting: Bool {
		switch task?.result.isCompleted {
		case .some(let isCompleted): return !isCompleted
		default: return false
		}
	}

	public override var isFinished: Bool {
		task?.result.isCompleted ?? false
	}

	private var runTask: (() -> Task<A>)?
	private var task: Task<A>?

	public let result: Promise<A>
	private let resolve: (Result<A, Error>) -> Void

	public init(generator: @escaping () -> Task<A>) {
		runTask = generator
		(result, resolve) = Promise<A>.pending()
	}

	public override func start() {
		guard task == nil, let runTask = runTask else { return }

		if isCancelled {
			resolve(.error(CancellationError()))
			task = .result(result)
			notifyKVO()
		}
		else {
			task = runTask()
			notifyKVO()

			task?.result.onComplete { [weak self] result in
				self?.resolve(result)
				self?.notifyKVO()
			}
		}
		self.runTask = nil
	}

	public override func cancel() {
		super.cancel()
		task?.cancel.dispose()
	}

	private func notifyKVO() {
		willChangeValue(forKey: "isExecuting")
		didChangeValue(forKey: "isExecuting")

		willChangeValue(forKey: "isFinished")
		didChangeValue(forKey: "isFinished")
	}
}
