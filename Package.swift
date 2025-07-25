// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenResearchKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "OpenResearchKit",
            targets: ["OpenResearchKit"])
    ],
    dependencies: [
    ],
    
    targets: [
        .target(
            name: "OpenResearchKit",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "OpenResearchKitTests",
            dependencies: ["OpenResearchKit"]),
    ]
)
