import Foundation
import OSLog

enum LibraryPersistence {
    private static let logger = Logger(subsystem: "com.bluelion.Hennessy", category: "LibraryPersistence")

    static func load() -> [LibraryMediaItem] {
        load(from: fileURL)
    }

    static func save(_ items: [LibraryMediaItem]) {
        save(items, to: fileURL)
    }

    static func load(from fileURL: URL) -> [LibraryMediaItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([LibraryMediaItem].self, from: data)
        } catch {
            logger.error("Unable to decode library at \(fileURL.path, privacy: .private): \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    static func save(_ items: [LibraryMediaItem], to fileURL: URL) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let existingData = try Data(contentsOf: fileURL)
                _ = try JSONDecoder().decode([LibraryMediaItem].self, from: existingData)
            }
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Unable to save library at \(fileURL.path, privacy: .private): \(error.localizedDescription, privacy: .public)")
        }
    }

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("Hennessy", isDirectory: true)
            .appendingPathComponent("library.json")
    }
}
