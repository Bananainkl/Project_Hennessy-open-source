import Foundation

enum AudioQualityServiceError: LocalizedError {
    case missingFFmpeg
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingFFmpeg: "找不到 ffmpeg，无法检测音质。"
        case .launchFailed(let message): "无法启动音质检测：\(message)"
        }
    }
}

final class AudioQualityService: @unchecked Sendable {
    func inspect(fileURL: URL) async throws -> AudioQualityInfo {
        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = Int64(values.fileSize ?? 0)
        let output = try await describe(fileURL: fileURL)
        return try AudioQualityParser.parse(ffmpegOutput: output, fileSize: fileSize)
    }

    private func describe(fileURL: URL) async throws -> String {
        try await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["ffmpeg", "-hide_banner", "-i", fileURL.path]
            process.environment = ProcessEnvironment.downloader
            let standardError = Pipe()
            process.standardOutput = FileHandle.nullDevice
            process.standardError = standardError
            do {
                try process.run()
            } catch {
                if (error as NSError).code == 2 { throw AudioQualityServiceError.missingFFmpeg }
                throw AudioQualityServiceError.launchFailed(error.localizedDescription)
            }
            let data = standardError.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(decoding: data, as: UTF8.self)
        }.value
    }
}

struct AudioQualityUpgradeInstallation: Equatable, Sendable {
    let replacement: LibraryMediaItem
    let backupURL: URL
}

struct AudioQualityUpgradeInstaller: Sendable {
    func install(item: LibraryMediaItem, candidateURL: URL, now: Date = Date()) throws -> AudioQualityUpgradeInstallation {
        let fileManager = FileManager.default
        let originalURL = item.fileURL
        guard fileManager.fileExists(atPath: originalURL.path), fileManager.fileExists(atPath: candidateURL.path) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let parentDirectory = originalURL.deletingLastPathComponent()
        let backupDirectory = parentDirectory
            .appendingPathComponent("Hennessy Quality Backups", isDirectory: true)
            .appendingPathComponent(Self.backupTimestamp(now), isDirectory: true)
        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let backupURL = uniqueFileURL(backupDirectory.appendingPathComponent(originalURL.lastPathComponent))
        let candidateExtension = candidateURL.pathExtension.isEmpty ? originalURL.pathExtension : candidateURL.pathExtension
        let proposedURL = originalURL.deletingPathExtension().appendingPathExtension(candidateExtension)
        let destinationURL = proposedURL == originalURL ? originalURL : uniqueFileURL(proposedURL)
        try fileManager.moveItem(at: originalURL, to: backupURL)
        do {
            try fileManager.moveItem(at: candidateURL, to: destinationURL)
        } catch {
            try? fileManager.moveItem(at: backupURL, to: originalURL)
            throw error
        }
        var replacement = item
        replacement.id = destinationURL.path
        replacement.filePath = destinationURL.path
        replacement.modeRawValue = DownloadMode.bestAudio.rawValue
        replacement.addedAt = now
        return AudioQualityUpgradeInstallation(replacement: replacement, backupURL: backupURL)
    }

    private func uniqueFileURL(_ url: URL) -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else { return url }
        let directory = url.deletingLastPathComponent()
        let stem = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var index = 2
        while true {
            let name = ext.isEmpty ? "\(stem) (\(index))" : "\(stem) (\(index)).\(ext)"
            let candidate = directory.appendingPathComponent(name)
            if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            index += 1
        }
    }

    private static func backupTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}
