// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Topojson",
    products: [
        .library(
            name: "Topojson",
            targets: ["Topojson"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Topojson",
            dependencies: []),
        .testTarget(
            name: "TopojsonTests",
            dependencies: ["Topojson"]),
    ]
)
