// swift-tools-version:5.3
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
        .package(url: "https://github.com/frogg/FredKit.git", from: "0.0.32")
    ],
    
    targets: [
        .target(
            name: "OpenResearchKit",
            dependencies: [
                "FredKit"
            ]
        ),
        .testTarget(
            name: "OpenResearchKitTests",
            dependencies: ["OpenResearchKit"]),
    ]
)
