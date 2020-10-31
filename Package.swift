// swift-tools-version:5.1
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
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.23.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.9.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "ZenSMTP",
            dependencies: ["NIO", "NIOFoundationCompat", "NIOSSL", "Logging"]),
        .testTarget(
            name: "ZenSMTPTests",
            dependencies: ["ZenSMTP"]),
    ]
)
