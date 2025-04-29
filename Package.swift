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
    ],
	dependencies: [
		.package(url: "https://github.com/P0ed/Fx", revision: "bebdc4fba9d122dcda69cbab9ba19ba614736702"),
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
