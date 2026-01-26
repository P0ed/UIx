import UIKit
import Fx

public struct RGBA32: Hashable, Codable {
	public var red: UInt8
	public var green: UInt8
	public var blue: UInt8
	public var alpha: UInt8
}

public struct RGBA: Hashable, Codable {
	public var red: CGFloat
	public var green: CGFloat
	public var blue: CGFloat
	public var alpha: CGFloat
}

public extension UIColor {

	convenience init(_ value: RGBA32) {
		self.init(
			red: CGFloat(value.red) / 255,
			green: CGFloat(value.green) / 255,
			blue: CGFloat(value.blue) / 255,
			alpha: CGFloat(value.alpha) / 255
		)
	}

	convenience init(_ value: RGBA) {
		self.init(
			red: value.red,
			green: value.green,
			blue: value.blue,
			alpha: value.alpha
		)
	}

	@objc convenience init(light: UIColor, dark: UIColor) {
		self.init(dynamicProvider: { traits in
			traits.isDarkStyle ? dark : light
		})
	}

	convenience init(light: RGBA32, dark: RGBA32) {
		self.init(light: UIColor(light), dark: UIColor(dark))
	}

	func opaque(over color: UIColor) -> UIColor {
		UIColor(modify(rgba) { [base = color.rgba] rgba in
			rgba.red = rgba.red * rgba.alpha + base.red * (1 - rgba.alpha)
			rgba.green = rgba.green * rgba.alpha + base.green * (1 - rgba.alpha)
			rgba.blue = rgba.blue * rgba.alpha + base.blue * (1 - rgba.alpha)
			rgba.alpha = 1
		})
	}

	func resolved(_ style: UIUserInterfaceStyle) -> UIColor {
		style == .unspecified ? self : resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
	}

	var invertedTheme: UIColor {
		UIColor(light: resolved(.dark), dark: resolved(.light))
	}

	var rgba32: RGBA32 {
		let rgba = self.rgba
		return RGBA32(
			red: UInt8(rgba.red * 255),
			green: UInt8(rgba.green * 255),
			blue: UInt8(rgba.blue * 255),
			alpha: UInt8(rgba.alpha * 255)
		)
	}

	var rgba: RGBA {
		var rgba = (0, 0, 0, 0) as (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
		getRed(&rgba.red, green: &rgba.green, blue: &rgba.blue, alpha: &rgba.alpha)
		return RGBA(
			red: rgba.red,
			green: rgba.green,
			blue: rgba.blue,
			alpha: rgba.alpha
		)
	}

	var isLight: Bool {
		var white: CGFloat = 0
		getWhite(&white, alpha: nil)
		return white > 0.5
	}

	var darkModeAdjustedDown: UIColor {
		UIColor(
			light: self,
			dark: UIColor(hsba: modify(hsba) { hsba in
				if hsba.saturation > 0.03 {
					hsba.saturation = (hsba.saturation + 0.5).clamped(to: 0...1)
				}
				hsba.brightness = (hsba.brightness - 0.5).clamped(to: 0...1)
			})
		)
	}
	var darkModeAdjustedUp: UIColor {
		UIColor(
			light: self,
			dark: UIColor(hsba: modify(hsba) { hsba in
				hsba.saturation = (hsba.saturation - 0.25).clamped(to: 0...1)
				hsba.brightness = (hsba.brightness + 0.5).clamped(to: 0...1)
			})
		)
	}
	@objc var darker: UIColor {
		UIColor(hsba: modify(hsba) { $0.brightness = ($0.brightness - 0.3).clamped(to: 0...1) })
	}
	@objc var lighter: UIColor {
		UIColor(hsba: modify(hsba) { $0.brightness = ($0.brightness + 0.3).clamped(to: 0...1) })
	}

	var highlighted: UIColor { isLight ? darker : lighter }
	func highlighted(_ isHighlighted: Bool) -> UIColor { isHighlighted ? highlighted : self }

	func map(light: (UIColor) -> UIColor, dark: (UIColor) -> UIColor) -> UIColor {
		UIColor(light: light(self), dark: dark(self))
	}
}

extension RGBA32: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: Int) {
		self = RGBA32(hex: value)
	}
}

public extension RGBA32 {

	init(hex value: Int) {
		self = RGBA32(
			red: value[byte: 2],
			green: value[byte: 1],
			blue: value[byte: 0],
			alpha: .max
		)
	}

	var hex: Int { Int(red) << 16 | Int(green) << 8 | Int(blue) }
	var hexString: String { String(format: "%06x", hex) }
}

private extension Int {
	subscript(byte byte: Int) -> UInt8 {
		let bits = byte * 8
		let mask = 0xFF << bits
		let shifted = (self & mask) >> bits
		return UInt8(shifted)
	}
}

public struct HSBA {
	public var hue: CGFloat
	public var saturation: CGFloat
	public var brightness: CGFloat
	public var alpha: CGFloat
}

public extension UIColor {

	var hsba: HSBA {
		var hsba = HSBA(hue: 0, saturation: 0, brightness: 0, alpha: 0)
		_ = getHue(&hsba.hue, saturation: &hsba.saturation, brightness: &hsba.brightness, alpha: &hsba.alpha)
		return hsba
	}

	convenience init(hsba: HSBA) {
		self.init(hue: hsba.hue, saturation: hsba.saturation, brightness: hsba.brightness, alpha: hsba.alpha)
	}
}
