import UIKit

public struct CellDisplaying<Cell: CellProtocol> {
	public var willDisplay: (Cell.Container, Cell, IndexPath) -> Void
	public var didEndDisplaying: (Cell.Container, Cell, IndexPath) -> Void

	public init(
		willDisplay: @escaping (Cell.Container, Cell, IndexPath) -> Void = { _, _, _ in },
		didEndDisplaying: @escaping (Cell.Container, Cell, IndexPath) -> Void = { _, _, _ in }
	) {
		self.willDisplay = willDisplay
		self.didEndDisplaying = didEndDisplaying
	}
}
