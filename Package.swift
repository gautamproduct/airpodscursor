// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AirPodsCursor",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "AirPodsCursor", targets: ["AirPodsCursor"]),
    ],
    targets: [
        // Pure, deterministic logic: pointer math, gesture + dwell detection, settings.
        .target(name: "AirPodsCursorCore"),
        // The macOS app: CoreMotion, IOBluetooth, CGEvent synthesis, MediaPlayer, UI.
        .executableTarget(
            name: "AirPodsCursor",
            dependencies: ["AirPodsCursorCore"],
            linkerSettings: [
                .linkedFramework("IOBluetooth"),
                .linkedFramework("CoreMotion"),
                .linkedFramework("MediaPlayer"),
                .linkedFramework("Carbon"),
            ]
        ),
        .testTarget(name: "AirPodsCursorCoreTests", dependencies: ["AirPodsCursorCore"]),
        .testTarget(name: "AirPodsCursorAppTests", dependencies: ["AirPodsCursor"]),
    ],
    swiftLanguageModes: [.v5]
)
