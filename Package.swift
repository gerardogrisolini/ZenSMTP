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
        .package(url: "https://github.com/apple/swift-nio.git", .branch("master")),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", .branch("master")),
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
