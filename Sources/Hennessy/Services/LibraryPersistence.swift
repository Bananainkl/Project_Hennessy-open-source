import Foundation

enum LibraryPersistence {
    static func load() -> [LibraryMediaItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([LibraryMediaItem].self, from: data)) ?? []
    }

    static func save(_ items: [LibraryMediaItem]) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Failed to save library: \(error)")
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
