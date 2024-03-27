import Foundation
import Fx

@inlinable
public func § <A, B> (f: Function<A, B>, x: A) -> B { f(x) }

/// Utility for writing extensions for functions with generic constraints.
public struct Function<A, B> {
	public var function: (A) -> B
	public init(_ function: @escaping (A) -> B) { self.function = function }
	public func callAsFunction(_ input: A) -> B { function(input) }
}

public extension Function where A == Void {
	func callAsFunction() -> B { function(()) }
}

extension Function: Semigroup, Monoid where B == Void {
	public static var empty: Function {
		ƒ { _ in }
	}
	public mutating func combine(_ x: Function) {
		self = ƒ { [f = function, g = x.function] x in f(x); g(x) }
	}
}

/// `⌥+f` Lifts the instance of `Function` to closures domain
public func ƒ<A, B>(_ function: Function<A, B>) -> (A) -> B { function.function }
/// `⌥+f` Lifts the instance of `Function` to closures domain
public func ƒ<A>(_ function: Function<Void, A>) -> () -> A { { function(()) } }

/// `⌥+f` Lifts the closure to `Function` domain
public func ƒ<A, B>(_ function: @escaping (A) -> B) -> Function<A, B> { Function(function) }

public func • <A, B, C>(f: Function<B, C>, g: Function<A, B>) -> Function<A, C> {
	ƒ § f.function • g.function
}
public func • <A, B, C>(f: @escaping (B) -> C, g: Function<A, B>) -> (A) -> C {
	f • g.function
}
public func • <B, C>(f: @escaping (B) -> C, g: Function<Void, B>) -> () -> C {
	f • g.callAsFunction
}
public func • <A, B, C>(f: Function<B, C>, g: @escaping (A) -> B) -> (A) -> C {
	f.function • g
}
public func • <B, C>(f: Function<B, C>, g: @escaping () -> B) -> () -> C {
	f.function • g
}

public extension Function where A == B {
	static func with(_ f: @escaping (A) -> Void) -> Function {
		ƒ { x in f(x); return x }
	}
	static func assigning<C>(_ keyPath: ReferenceWritableKeyPath<A, C>, to value: C) -> Function {
		with • ƒ § .assigning(keyPath, to: value)
	}
	static func modify(_ f: @escaping (inout A) -> Void) -> Function {
		ƒ { x in Fx.modify(x, f) }
	}
}

public extension Function where B == Void {
	static func assigning<C>(_ keyPath: ReferenceWritableKeyPath<A, C>, to value: C) -> Function {
		Self { $0[keyPath: keyPath] = value }
	}
}

public extension Function {
	var optional: Function<A?, B?> {
		ƒ { x in x.map(function) }
	}
	static func `if`(_ predicate: @escaping (A) -> Bool, _ true: @escaping (A) -> B, _ false: @escaping (A) -> B) -> Function {
		ƒ { predicate($0) ? `true`($0) : `false`($0) }
	}
}

public extension Function where A == Bool {
	static func fold(_ true: @escaping () -> B, _ false: @escaping () -> B) -> Function {
		ƒ { $0 ? `true`() : `false`() }
	}
	static func fold(_ true: @escaping @autoclosure () -> B, _ false: @escaping @autoclosure () -> B) -> Function {
		ƒ { $0 ? `true`() : `false`() }
	}
}
