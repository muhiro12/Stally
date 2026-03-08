// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package( // swiftlint:disable:this prefixed_toplevel_constant
    name: "StallyLibrary",
    platforms: [
        .iOS(.v18)
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
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "StallyLibrary",
            dependencies: [
                .product(
                    name: "MHDeepLinking",
                    package: "MHPlatform"
                )
            ],
            path: ".",
            sources: [
                "Sources"
            ]
        ),
        .testTarget(
            name: "StallyLibraryTests",
            dependencies: [
                "StallyLibrary",
                .product(
                    name: "MHDeepLinking",
                    package: "MHPlatform"
                )
            ],
            path: "Tests/Default"
        )
    ]
)
