import Foundation
import ObjectiveC.runtime
import Fx

public extension UnsafeRawPointer {

	static func allocateByte() -> UnsafeRawPointer {
		id(UnsafeMutablePointer<Int8>.allocate(capacity: 1))
	}
}

public extension NSObject {

	func associatedObject<A>(_ key: UnsafeRawPointer) -> IO<A?> {
		IO(
			get: { [weak self] in self?.getAssociatedObject(key: key) },
			set: { [weak self] in self?.setAssociatedObject(key: key, object: $0) }
		)
	}

	func getAssociatedObject<T>(key: UnsafeRawPointer) -> T? {
		objc_getAssociatedObject(self, key) as? T
	}
	func setAssociatedObject<T>(key: UnsafeRawPointer, object: T?, policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
		objc_setAssociatedObject(self, key, object, policy)
	}
}

public extension NSObject {

	private static let lifetimeKey = UnsafeRawPointer.allocateByte()

	var lifetime: CompositeDisposable {
		if let disposable: CompositeDisposable = getAssociatedObject(key: NSObject.lifetimeKey) { return disposable }
		let disposable = CompositeDisposable()
		setAssociatedObject(key: NSObject.lifetimeKey, object: disposable)
		return disposable
	}

	var dealloc: Promise<Void> {
		.init { resolve in
			lifetime += { resolve(.void) }
		}
	}
}

public extension SelfConstraints where Self: NSObject {

	@discardableResult
	func apply<A>(_ value: Property<A>, _ f: @escaping (Self, A) -> Void) -> ManualDisposable {
		lifetime += value.observe { [weak self] value in if let self = self { f(self, value) } }
	}
	@discardableResult
	func bind<A>(_ keyPath: ReferenceWritableKeyPath<Self, A>, to value: Property<A>) -> ManualDisposable {
		apply(value) { `self`, value in self[keyPath: keyPath] = value }
	}
	@discardableResult
	func bind<A>(_ keyPath: ReferenceWritableKeyPath<Self, A?>, to value: Property<A>) -> ManualDisposable {
		apply(value) { `self`, value in self[keyPath: keyPath] = value }
	}
}

public final class ActionTrampoline<A>: NSObject {
	private let action: (A) -> Void
	public var selector: Selector { #selector(objCAction) }

	public init(_ action: @escaping (A) -> Void) {
		self.action = action
	}

	@objc private func objCAction(_ sender: Any) {
		action(sender as! A)
	}
}

public final class ControlActionTrampoline<A>: NSObject {
	private let action: (A, UIEvent) -> Void
	public var selector: Selector { #selector(objCAction) }

	public init(_ action: @escaping (A, UIEvent) -> Void) {
		self.action = action
	}

	@objc private func objCAction(_ sender: Any, _ event: UIEvent) {
		action(sender as! A, event)
	}
}

public extension FileManager {
	private static var defautSizeResourceKeys: [URLResourceKey] {
		[
			.isDirectoryKey,
			.isRegularFileKey,
			.fileAllocatedSizeKey,
			.totalFileAllocatedSizeKey
		]
	}

	func recursiveFileSize(at url: URL) -> Int {
		let values = try? url.resourceValues(forKeys: Set(FileManager.defautSizeResourceKeys))

		if values?.isDirectory == true {
			return enumerator(at: url, includingPropertiesForKeys: FileManager.defautSizeResourceKeys)?
				.compactMap { try? ($0 as? URL)?.resourceValues(forKeys: Set(FileManager.defautSizeResourceKeys)) }
				.compactMap { $0?.fileSize }
				.reduce(0, +) ?? 0
		} else if values?.isRegularFile == true {
			return values?.fileSize ?? 0
		} else {
			return 0
		}
	}
}

private extension URLResourceValues {
	var fileSize: Int? {
		totalFileAllocatedSize ?? fileAllocatedSize
	}
}

public final class ObjCContainer<A>: NSObject {
	public let value: A
	public init(_ value: A) {
		self.value = value
	}
}

public extension NSObject {

	static func swizzle(_ original: Selector, _ swizzled: Selector) {
		guard
			let originalMethod = class_getInstanceMethod(self, original),
			let swizzledMethod = class_getInstanceMethod(self, swizzled)
			else { return }
		method_exchangeImplementations(originalMethod, swizzledMethod)
	}
}
