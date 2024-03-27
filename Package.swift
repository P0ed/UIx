// swift-tools-version: 5.10

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
        .library(
            name: "Kletki",
            targets: ["Kletki"]
		),
    ],
	dependencies: [
		.package(url: "https://github.com/P0ed/Fx", from: "3.2.0"),
	],
    targets: [
        .target(
            name: "Kletki"
		),
        .target(
            name: "UIx",
			dependencies: ["Fx", "Kletki"]
		),
        .testTarget(
            name: "UIxTests",
            dependencies: ["UIx"]
		),
    ]
)
