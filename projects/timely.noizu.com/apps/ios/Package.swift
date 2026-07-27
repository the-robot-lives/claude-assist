// swift-tools-version: 6.0

import PackageDescription

// The iOS companion is declared iOS-only on purpose. It consumes iOS-only
// SwiftUI and AuthenticationServices API, so `swift build` on a Mac — which
// targets macOS — cannot compile it. Build and test with:
//
//   xcodebuild -scheme TimelyiOS -destination 'generic/platform=iOS Simulator' build
//   xcodebuild -scheme TimelyiOS -destination 'platform=iOS Simulator,name=iPhone 17' test
//
// See README.md.
let package = Package(
    name: "TimelyiOS",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TimelyiOS", targets: ["TimelyiOS"])
    ],
    dependencies: [
        .package(path: "../shared/TimelyKit")
    ],
    targets: [
        .target(
            name: "TimelyiOS",
            dependencies: [.product(name: "TimelyKit", package: "TimelyKit")],
            path: "Sources/TimelyiOS",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TimelyiOSTests",
            dependencies: ["TimelyiOS"],
            path: "Tests/TimelyiOSTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
