// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "LocalNotificationCenter",
    platforms: [.iOS(.v12)],
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
