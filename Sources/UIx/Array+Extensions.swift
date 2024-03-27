import Foundation
import Fx

extension Optional: IteratorProtocol {

	public var sequence: AnySequence<Wrapped> {
		.init { self }
	}

	public mutating func next() -> Wrapped? {
		defer { self = .none }
		return self
	}
}

public extension Sequence {
	var asArray: [Iterator.Element] { Array(self) }
}

public extension Sequence where Element: OptionalType {
	var compact: [Element.A] { compactMap(\.optional) }
}

public extension Sequence where Element: Sequence {
	var flatten: [Element.Element] { flatMap { $0 } }
}

public extension Optional {
	var asArray: [Wrapped] { Array(sequence) }
}

public extension Optional where Wrapped: Monoid {
	var compact: Wrapped { self ?? .empty }
}

public extension Collection {
	var nonempty: Self? { isEmpty ? nil : self }
}

public extension Array {
	func groupBy<A>(_ f: (Int) -> A) -> [A: [Element]] {
		var dictionary: [A: [Element]] = [:]

		for (index, object) in enumerated() {
			let key = f(index)
			let subarray = dictionary[key]

			if var subarray = subarray {
				subarray.append(object)
				dictionary[key] = subarray
			} else {
				dictionary[key] = [object]
			}
		}

		return dictionary
	}

	func groupBy<A>(_ f: (Element) -> A) -> [A: [Element]] {
		var dictionary: [A: [Element]] = [:]

		forEach { object in
			let key = f(object)
			let subarray = dictionary[key]

			if var subarray = subarray {
				subarray.append(object)
				dictionary[key] = subarray
			} else {
				dictionary[key] = [object]
			}
		}

		return dictionary
	}
}

public extension Array {
	/// Return nil if index out of range
	/// Time: O(1)
	subscript(safe index: Index) -> Element? {
		0 <= index && index < count ? self[index] : nil
	}
}
