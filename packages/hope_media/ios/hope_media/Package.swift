// swift-tools-version: 5.9
// HOPE – complemento de vídeo MP4 (H.264) para iOS con AVFoundation.
// Mismo formato que la plantilla de complementos de Flutter: se puede usar
// con Swift Package Manager o con CocoaPods (../hope_media.podspec).

import PackageDescription

let package = Package(
    name: "hope_media",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "hope-media", targets: ["hope_media"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "hope_media",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
