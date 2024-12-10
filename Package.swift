// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LocalNotificationCenter",
    platforms: [
        .macOS(.v14),
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "LocalNotificationCenter",
            targets: ["LocalNotificationCenter"]
        ),
    ],
    targets: [
        .target(
            name: "LocalNotificationCenter"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
