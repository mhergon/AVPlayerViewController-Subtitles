// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AVPlayerViewController-Subtitles",
    platforms: [
      .iOS(.v8), .tvOS(.v9)
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
