// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AVPlayerViewController-Subtitles",
    platforms: [
      .iOS(.v12), .tvOS(.v12), .macOS(.v12)
    ],
    products: [
        .library(
            name: "AVPlayerViewController-Subtitles",
            targets: ["AVPlayerViewController-Subtitles"]),
    ],
    targets: [
        .target(
            name: "AVPlayerViewController-Subtitles",
            path: "Source"
        )
    ]
)
