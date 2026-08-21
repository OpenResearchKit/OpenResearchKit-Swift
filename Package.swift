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
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.10.2"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.20")
    ],
    targets: [
        .target(
            name: "OpenResearchKit",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ],
            plugins: [
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ]
        ),
        .testTarget(
            name: "OpenResearchKitTests",
            dependencies: ["OpenResearchKit"]
        ),
    ]
)
