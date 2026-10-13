import Foundation
import AppKit

final class XcodeProjectManager {
    func extractProjectArchive(at archiveURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let destinationDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("base44-xcode-\(UUID().uuidString)")

        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        let unzipProcess = Process()
        unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzipProcess.arguments = ["-q", archiveURL.path, "-d", destinationDirectory.path]
        try unzipProcess.run()
        unzipProcess.waitUntilExit()

        let enumerator = fileManager.enumerator(at: destinationDirectory, includingPropertiesForKeys: nil)

        while let item = enumerator?.nextObject() as? URL {
            if item.pathExtension == "xcodeproj" || item.pathExtension == "xcworkspace" {
                return item
            }
        }

        throw NSError(
            domain: "XcodeProjectManager",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "No .xcodeproj or .xcworkspace was found in the downloaded archive."]
        )
    }

    func openInXcode(projectURL: URL) -> Bool {
        let bundleIdentifier = "com.apple.dt.Xcode"
        let result = NSWorkspace.shared.open([projectURL], withAppBundleIdentifier: bundleIdentifier, options: [], additionalEventParamDescriptor: nil, launchIdentifiers: nil)
        return result
    }

    func buildForSimulator(projectURL: URL, scheme: String) throws -> String {
        let projectDirectory = projectURL.deletingLastPathComponent()
        let xcodebuild = Process()
        xcodebuild.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        xcodebuild.currentDirectoryURL = projectDirectory
        xcodebuild.arguments = [
            "-project",
            projectURL.path,
            "-scheme",
            scheme,
            "-destination",
            "platform=iOS Simulator,name=iPhone 15",
            "build"
        ]

        let outputPipe = Pipe()
        xcodebuild.standardOutput = outputPipe
        xcodebuild.standardError = outputPipe

        try xcodebuild.run()
        xcodebuild.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)

        if xcodebuild.terminationStatus != 0 {
            throw NSError(
                domain: "XcodeProjectManager",
                code: Int(xcodebuild.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: output]
            )
        }

        return output
    }
}
