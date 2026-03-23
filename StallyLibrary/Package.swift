// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package( // swiftlint:disable:this prefixed_toplevel_constant
    name: "StallyLibrary",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "StallyLibrary",
            targets: ["StallyLibrary"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/muhiro12/MHPlatform.git",
            "1.0.0"..<"2.0.0"
        )
    ],
    targets: [
        .target(
            name: "StallyLibrary",
            dependencies: [
                .product(
                    name: "MHPlatformCore",
                    package: "MHPlatform"
                )
            ],
            path: ".",
            sources: [
                "Sources"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "StallyLibraryTests",
            dependencies: [
                "StallyLibrary",
                .product(
                    name: "MHPlatformCore",
                    package: "MHPlatform"
                )
            ],
            path: "Tests/Default"
        )
    ]
)
