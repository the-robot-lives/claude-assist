// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TimelyMac",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TimelyMac", targets: ["TimelyMac"])
    ],
    dependencies: [
        // The shared domain. macOS is the canonical implementation of this
        // domain and the only capture agent, but the *types* now live in
        // TimelyKit so macOS and the companions cannot drift apart.
        .package(path: "../shared/TimelyKit")
    ],
    targets: [
        .executableTarget(
            name: "TimelyMac",
            dependencies: [.product(name: "TimelyKit", package: "TimelyKit")]
        )
    ]
)
