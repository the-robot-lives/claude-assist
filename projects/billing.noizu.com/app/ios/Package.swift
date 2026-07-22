// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BillingNoizu",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(name: "BillingNoizu", targets: ["BillingNoizu"])
    ],
    targets: [
        .executableTarget(
            name: "BillingNoizu",
            path: "Sources/BillingNoizu"
        )
    ]
)
