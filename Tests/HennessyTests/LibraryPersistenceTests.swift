import XCTest
@testable import Hennessy

final class LibraryPersistenceTests: XCTestCase {
    func testSaveDoesNotOverwriteCorruptLibraryData() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HennessyLibraryPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("library.json")
        let originalData = Data("{ damaged library".utf8)
        try originalData.write(to: fileURL)

        LibraryPersistence.save([], to: fileURL)

        XCTAssertEqual(try Data(contentsOf: fileURL), originalData)
    }
}
