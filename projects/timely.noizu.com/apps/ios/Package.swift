// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TimelyiOS",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .executable(name: "TimelyiOS", targets: ["TimelyiOS"])
    ],
    targets: [
        .executableTarget(name: "TimelyiOS")
    ]
)
