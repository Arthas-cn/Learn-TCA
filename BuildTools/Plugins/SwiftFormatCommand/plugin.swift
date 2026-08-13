import Foundation
import PackagePlugin

@main
struct SwiftFormatCommand: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {
        try runSwiftFormat(
            tool: try context.tool(named: "swiftformat"),
            directory: context.package.directory.removingLastComponent(),
            arguments: arguments
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftFormatCommand: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        var extractor = ArgumentExtractor(arguments)
        _ = extractor.extractOption(named: "target")
        try runSwiftFormat(
            tool: try context.tool(named: "swiftformat"),
            directory: context.xcodeProject.directory,
            arguments: extractor.remainingArguments
        )
    }
}
#endif

private func runSwiftFormat(
    tool: PluginContext.Tool,
    directory: PackagePlugin.Path,
    arguments: [String]
) throws {
    var processArguments = [directory.string]
    if !arguments.contains(where: { $0 == "--swift-version" || $0.hasPrefix("--swift-version=") }) {
        processArguments += ["--swift-version", "6.3"]
    }
    if !arguments.contains(where: { $0 == "--exclude" || $0.hasPrefix("--exclude=") }) {
        processArguments += ["--exclude", "BuildTools"]
    }
    processArguments += arguments

    let process = Process()
    process.executableURL = URL(fileURLWithPath: tool.path.string)
    process.arguments = processArguments
    try process.run()
    process.waitUntilExit()

    guard process.terminationReason == .exit, process.terminationStatus == 0 else {
        Diagnostics.error(
            "swiftformat failed: \(process.terminationReason):\(process.terminationStatus)"
        )
        return
    }
    print("Formatted Swift sources in \(directory.string)")
}
