// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PhotoAlbumOrganizer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Vapor 4.x web framework
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.0"),
        // Fluent ORM
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // SQLite database driver
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0")
    ],
    targets: [
        .executableTarget(
            name: "PhotoAlbumOrganizer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
            ],
            path: "Sources/App"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "PhotoAlbumOrganizer"),
                .product(name: "XCTVapor", package: "vapor")
            ],
            path: "Tests/AppTests"
        )
    ]
)
