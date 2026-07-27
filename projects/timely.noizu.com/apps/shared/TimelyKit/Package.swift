// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TimelyKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "TimelyKit", targets: ["TimelyKit"])
    ],
    targets: [
        .target(
            name: "TimelyKit",
            path: "Sources/TimelyKit",
            swiftSettings: [.swiftLanguageMode(.v6)],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "TimelyKitTests",
            dependencies: ["TimelyKit"],
            path: "Tests/TimelyKitTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
