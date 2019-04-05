// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZenSMTP",
    products: [
        .library(
            name: "ZenSMTP",
            targets: ["ZenSMTP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.0.1"),
    ],
    targets: [
        .target(
            name: "ZenSMTP",
            dependencies: ["NIO", "NIOFoundationCompat", "NIOSSL"]),
        .testTarget(
            name: "ZenSMTPTests",
            dependencies: ["ZenSMTP"]),
    ]
)
