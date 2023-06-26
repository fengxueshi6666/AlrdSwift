// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Alrdswift",
    platforms:[.iOS(.v12),.macOS(.v10_14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Alrdswift",
            targets: ["Alrdswift"])
    ],
    dependencies: [
        .package(url: "https://github.com/fengxueshi6666/ALRDTransitXProvider.git", from: "0.0.9"),
        .package(url: "https://github.com/samiyr/SwiftyPing.git", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Alrdswift",
            dependencies: [
                .product(name: "ALRDTransitXProvider",package: "ALRDTransitXProvider"),
                .product(name: "SwiftyPing",package: "SwiftyPing"),
                .target(name: "AlrdDns")
            ],
            path: "Sources/Alrdswift"
        ),
        .target(
            name: "AlrdDns",
            publicHeadersPath: "include",
            linkerSettings: [.linkedLibrary("resolv")]
        ),
        .testTarget(
            name: "AlrdswiftTests",
            dependencies: ["Alrdswift"])
    ]
)
