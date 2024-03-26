// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Layout",
	platforms: [
		.iOS(.v14)
	],
    products: [
        .library(
            name: "Layout",
            targets: ["Layout"]
		),
    ],
	dependencies: [
		.package(url: "https://github.com/P0ed/Fx", from: "3.1.0"),
	],
    targets: [
        .target(
            name: "Layout",
			dependencies: ["Fx"]
		),
        .testTarget(
            name: "LayoutTests",
            dependencies: ["Layout"]
		),
    ]
)
