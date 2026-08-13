// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v13)],
    products: [
        .plugin(name: "FormatSources", targets: ["SwiftFormatCommand"]),
    ],
    targets: [
        .binaryTarget(
            name: "swiftformat",
            path: "Artifacts/swiftformat.artifactbundle"
        ),
        .plugin(
            name: "SwiftFormatCommand",
            capability: .command(
                intent: .custom(
                    verb: "format-sources",
                    description: "Format Swift sources with SwiftFormat"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Rewrite formatted Swift source files"),
                ]
            ),
            dependencies: [
                "swiftformat",
            ]
        ),
    ]
)
