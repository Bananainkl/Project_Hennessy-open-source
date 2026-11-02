import XCTest
@testable import Hennessy

final class DownloadResultTests: XCTestCase {
    func testFinalURLsPreservesEveryPlaylistOutput() {
        let result = DownloadResult(
            exitCode: 0,
            outputText: "下载完成：/tmp/first.m4a\n下载完成：/tmp/second.m4a\n",
            errorText: "",
            thumbnailURL: nil,
            songTitle: nil,
            artistName: nil
        )

        XCTAssertEqual(result.finalURLs.map(\.path), ["/tmp/first.m4a", "/tmp/second.m4a"])
    }

    func testMediaDiscoveryReturnsAllMatchingPlaylistFilesAndSkipsSidecars() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HennessyPlaylistFiles-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for name in ["a-song.m4a", "b-song.webm", "cover.jpg", "captions.vtt", "incomplete.part"] {
            try Data().write(to: directory.appendingPathComponent(name))
        }

        let files = try DownloaderService().mediaFiles(in: directory, mode: .bestAudio)

        XCTAssertEqual(Set(files.map(\.lastPathComponent)), ["a-song.m4a", "b-song.webm"])
    }

    func testPlaylistOutputTemplateIncludesUniqueMediaID() {
        let template = DownloaderService.outputTemplate(in: URL(fileURLWithPath: "/tmp/download"))

        XCTAssertTrue(template.contains("%(id)s"))
    }

    func testTerminatedDownloadProcessThrowsCancellation() async throws {
        let service = DownloaderService()
        let task = Task {
            try await service.runProcess(arguments: ["sh", "-c", "exec sleep 10"], onOutput: nil)
        }
        try await Task.sleep(for: .milliseconds(100))
        service.cancel()

        do {
            _ = try await task.value
            XCTFail("A cancelled process must not be returned as a failed download")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
    }
}
