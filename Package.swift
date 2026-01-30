// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyTooltip",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftyTooltip",
            targets: ["SwiftyTooltip"]),
    ],
    dependencies: [
        .package(url: "https://github.com/fatbobman/SwiftUIOverlayContainer.git", from: "2.0.0"),
        .package(url: "https://github.com/siteline/swiftui-introspect", "1.3.0"..<"27.0.0"),
        .package(
           url: "https://github.com/apple/swift-collections.git",
           .upToNextMajor(from: "1.0.5")
         )

    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftyTooltip",
            dependencies: [.product(name:"SwiftUIOverlayContainer", package: "SwiftUIOverlayContainer"),
                           .product(name: "SwiftUIIntrospect", package: "swiftui-introspect"),
                           .product(name: "Collections", package: "swift-collections")]),
        .testTarget(
            name: "SwiftyTooltipTests",
            dependencies: ["SwiftyTooltip"]
        ),
    ]
)
