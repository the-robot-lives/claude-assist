// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TheRobotPlansMobile",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "TheRobotPlansCore", targets: ["TheRobotPlansCore"]),
        .executable(name: "TheRobotPlansiOS", targets: ["TheRobotPlansiOS"])
    ],
    targets: [
        .target(
            name: "TheRobotPlansCore",
            path: "Sources/TheRobotPlansCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "TheRobotPlansiOS",
            dependencies: ["TheRobotPlansCore"],
            path: "Sources/TheRobotPlansiOS",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TheRobotPlansCoreTests",
            dependencies: ["TheRobotPlansCore"],
            path: "Tests/TheRobotPlansCoreTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
