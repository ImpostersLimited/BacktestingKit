// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BacktestingKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "BacktestingKit",
            targets: ["BacktestingKit"]
        ),
        .executable(
            name: "BacktestingKitTrialDemo",
            targets: ["BacktestingKitTrialDemo"]
        )
    ],
    targets: [
        .target(
            name: "BacktestingKit",
            path: "BacktestingKit",
            exclude: [
                "ARCHITECTURE.md",
                "BacktestingKit.docc"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "BacktestingKitTrialDemo",
            dependencies: ["BacktestingKit"],
            path: "Examples/TrialRunDemo"
        ),
        .testTarget(
            name: "BacktestingKitTests",
            dependencies: ["BacktestingKit"],
            path: "Tests/BacktestingKitTests"
        )
    ]
)
