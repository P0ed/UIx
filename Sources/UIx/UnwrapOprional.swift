public extension Optional {

	func unwrap(_ fallbackError: @autoclosure () -> Error) throws -> Wrapped {
		guard let value = self
			else { throw fallbackError() }
		return value
	}

	func zip<B>(_ other: B?) -> (Wrapped, B)? {
		flatMap { x in other.map { y in (x, y) } }
	}

}

public extension Optional {
	var isNil: Bool { self == nil }
}

public extension Optional where Wrapped: Collection {
	var isNilOrEmpty: Bool {
		map(\.isEmpty) ?? true
	}
}

infix operator ?! : NilCoalescingPrecedence

public func ?! <A>(optional: A?, fallbackError: @autoclosure () -> Error) throws -> A {
	try optional.unwrap(fallbackError())
}
