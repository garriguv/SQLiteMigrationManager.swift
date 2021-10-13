// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "SQLiteMigrationManager.swift",
    products: [
        .library(name: "SQLiteMigrationManager", targets: ["SQLiteMigrationManager"])
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", .upToNextMinor(from: "0.12.2"))
    ],
    targets: [
        .target(
            name: "SQLiteMigrationManager",
            dependencies: ["SQLite"],
            path: "Sources",
            sources: ["SQLiteMigrationManager.swift"]),
        .testTarget(
            name: "SQLiteMigrationManagerTests",
            dependencies: ["SQLiteMigrationManager"],
            path: "Tests",
            sources: ["SQLiteMigrationManagerTests.swift"])
    ])
