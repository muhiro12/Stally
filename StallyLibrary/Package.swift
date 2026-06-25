// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package( // swiftlint:disable:this prefixed_toplevel_constant
    name: "StallyLibrary",
    defaultLocalization: "en",
    platforms: [
        .iOS("27.0")
    ],
    products: [
        .library(
            name: "StallyLibrary",
            targets: ["StallyLibrary"]
        )
    ],
    targets: [
        .target(
            name: "StallyLibrary",
            path: ".",
            sources: [
                "Sources"
            ]
        ),
        .testTarget(
            name: "StallyLibraryTests",
            dependencies: ["StallyLibrary"],
            path: "Tests/Default"
        )
    ]
)
