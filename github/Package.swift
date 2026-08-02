// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GitHubTokenManager",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "github-token-manager",
            targets: ["GitHubTokenManager"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "GitHubTokenManager"
        ),
        .testTarget(
            name: "GitHubTokenManagerTests",
            dependencies: ["GitHubTokenManager"]
        ),
    ]
)
