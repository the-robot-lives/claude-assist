// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BillingNoizuMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BillingNoizuMac", targets: ["BillingNoizuMac"])
    ],
    targets: [
        .executableTarget(
            name: "BillingNoizuMac",
            path: "Sources/BillingNoizuMac"
        )
    ]
)
