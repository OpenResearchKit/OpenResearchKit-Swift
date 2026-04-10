// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "OpenResearchKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "OpenResearchKit",
            targets: ["OpenResearchKit"]
        )
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
            dependencies: ["OpenResearchKit"]
        ),
    ]
)
