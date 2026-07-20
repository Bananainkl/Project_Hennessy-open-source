import XCTest
@testable import Hennessy

final class PlaybackResumePolicyTests: XCTestCase {
    func testCompletedTrackRestartsFromBeginning() {
        XCTAssertTrue(
            PlaybackResumePolicy.shouldRestart(
                didReachEnd: true,
                currentTime: 240,
                duration: 240
            )
        )
    }

    func testPausedTrackContinuesFromCurrentPosition() {
        XCTAssertFalse(
            PlaybackResumePolicy.shouldRestart(
                didReachEnd: false,
                currentTime: 82,
                duration: 240
            )
        )
    }

    func testTrackAtDurationRestartsEvenBeforeEndNotificationArrives() {
        XCTAssertTrue(
            PlaybackResumePolicy.shouldRestart(
                didReachEnd: false,
                currentTime: 239.9,
                duration: 240
            )
        )
    }
}
