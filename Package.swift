// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ActorCoreBluetooth",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "ActorCoreBluetooth",
            targets: ["ActorCoreBluetooth"]),
    ],
    targets: [
        // Internal runtime target - contains all @unchecked Sendable conformances
        .target(
            name: "ActorCoreBluetoothRuntime",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        
        // Public facade target - uses internal import of runtime module
        // to ensure @unchecked Sendable conformances do not leak to clients.
        .target(
            name: "ActorCoreBluetooth",
            dependencies: [
                .target(name: "ActorCoreBluetoothRuntime")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        
        .testTarget(
            name: "ActorCoreBluetoothTests",
            dependencies: ["ActorCoreBluetooth"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
