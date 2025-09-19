// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "UIx",
	platforms: [
		.iOS(.v14)
	],
    products: [
        .library(
            name: "UIx",
            targets: ["UIx"]
		),
    ],
	dependencies: [
		.package(url: "https://github.com/P0ed/Fx", branch: "main"),
	],
    targets: [
        .target(
            name: "UIx",
			dependencies: ["Fx"]
		),
        .testTarget(
            name: "UIxTests",
            dependencies: ["UIx"]
		),
    ]
)
