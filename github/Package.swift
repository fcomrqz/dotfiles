// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GitHubAppHelper",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "github-app-helper",
            targets: ["GitHubAppHelper"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "GitHubAppHelper"
        ),
        .testTarget(
            name: "GitHubAppHelperTests",
            dependencies: ["GitHubAppHelper"]
        ),
    ]
)
