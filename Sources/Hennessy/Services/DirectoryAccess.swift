import Foundation

struct SecurityScopedAccess {
    let url: URL
    let isActive: Bool

    func stop() {
        if isActive {
            url.stopAccessingSecurityScopedResource()
        }
    }
}

enum DirectoryAccess {
    private static let outputDirectoryBookmarkKey = "outputDirectoryBookmark"

    static var defaultOutputDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")
            .appendingPathComponent("Media")
    }

    static func restoredOutputDirectory() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: outputDirectoryBookmarkKey) else { return nil }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                saveOutputDirectory(url)
            }
            return url
        } catch {
            UserDefaults.standard.removeObject(forKey: outputDirectoryBookmarkKey)
            return nil
        }
    }

    static func saveOutputDirectory(_ url: URL) {
        do {
            let data = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: outputDirectoryBookmarkKey)
        } catch {
            assertionFailure("Failed to save output directory bookmark: \(error)")
        }
    }

    static func startAccessing(_ url: URL) -> SecurityScopedAccess {
        SecurityScopedAccess(url: url, isActive: url.startAccessingSecurityScopedResource())
    }
}
