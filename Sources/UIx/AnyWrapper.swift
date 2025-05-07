import Fx

@propertyWrapper public struct AnyWrapper<Value, Projected> {
	public var value: IO<Value>
	public var projected: () -> Projected

	public var wrappedValue: Value {
		get { value.value }
		nonmutating set { value.value = newValue }
	}

	public var projectedValue: Projected {
		projected()
	}

	public init(value: IO<Value>, projected: @escaping () -> Projected) {
		self.value = value
		self.projected = projected
	}
}

public extension AnyWrapper where Projected == Property<Value> {

	init(observable io: IO<Value>) {
		let observable = MutableProperty(io.value)
		self = AnyWrapper(
			value: IO(get: observable.io.get, set: observable.io.set • Fn.with(io.set)),
			projected: { observable.readonly }
		)
	}
}

public extension AnyWrapper {
	init(_ wrapper: AnyWrapper) {
		self = wrapper
	}
}

@propertyWrapper public struct AnyReadonlyWrapper<Value, Projected> {
	public var value: Readonly<Value>
	public var projected: () -> Projected

	public var wrappedValue: Value {
		value.value
	}

	public var projectedValue: Projected {
		projected()
	}

	public init(value: Readonly<Value>, projected: @escaping () -> Projected) {
		self.value = value
		self.projected = projected
	}
}

public extension AnyReadonlyWrapper {
	init(_ wrapper: AnyReadonlyWrapper) {
		self = wrapper
	}
}

public extension IO {
	init(_ value: A) {
		var value = value
		self = IO(get: { value }, set: { value = $0 })
	}
	func map<B>(get: @escaping (A) -> B, set: @escaping (B) -> A) -> IO<B> {
		IO<B>(get: get • self.get, set: self.set • set)
	}
	func map<B>(_ keyPath: WritableKeyPath<A, B>) -> IO<B> {
		IO<B>(
			get: { value[keyPath: keyPath] },
			set: { value[keyPath: keyPath] = $0 }
		)
	}
}
