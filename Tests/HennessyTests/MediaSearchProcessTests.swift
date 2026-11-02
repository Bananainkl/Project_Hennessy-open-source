import XCTest
@testable import Hennessy

final class MediaSearchProcessTests: XCTestCase {
    func testCaptureDrainsLargeStandardOutputAndErrorConcurrently() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "head -c 1048576 /dev/zero | tr '\\000' o; head -c 1048576 /dev/zero | tr '\\000' e >&2"]

        let result = try MediaSearchService.captureOutput(from: process)

        XCTAssertEqual(result.output.count, 1_048_576)
        XCTAssertEqual(result.errorOutput.count, 1_048_576)
        XCTAssertEqual(process.terminationStatus, 0)
    }

    func testCaptureClosesPipeReadersWhenProcessLaunchFails() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/missing/hennessy-test-command")

        XCTAssertThrowsError(try MediaSearchService.captureOutput(from: process))
    }
}
