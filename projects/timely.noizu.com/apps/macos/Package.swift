// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TimelyMac",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TimelyMac", targets: ["TimelyMac"])
    ],
    targets: [
        .executableTarget(name: "TimelyMac")
    ]
)

