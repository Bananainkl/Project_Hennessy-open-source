import XCTest
@testable import Hennessy

final class DuplicateMediaMatcherTests: XCTestCase {
    func testMatchesYouTubeURLVariantsWithinSameMediaFamily() {
        let item = libraryItem(
            title: "等一分钟",
            artist: "徐誉滕",
            sourceURL: "https://www.youtube.com/watch?v=abc123&utm_source=test",
            mode: .bestAudio
        )

        let match = DuplicateMediaMatcher.bestMatch(
            in: [item],
            lookup: DuplicateMediaLookup(
                sourceURL: "https://music.youtube.com/watch?v=abc123&feature=share",
                title: nil,
                artist: nil,
                mode: .mp3
            )
        )

        XCTAssertEqual(match?.id, item.id)
    }

    func testDoesNotMatchSameURLAcrossAudioAndVideoFamilies() {
        let item = libraryItem(
            title: "等一分钟",
            artist: "徐誉滕",
            sourceURL: "https://www.youtube.com/watch?v=abc123",
            mode: .video
        )

        let match = DuplicateMediaMatcher.bestMatch(
            in: [item],
            lookup: DuplicateMediaLookup(
                sourceURL: "https://youtu.be/abc123",
                title: nil,
                artist: nil,
                mode: .bestAudio
            )
        )

        XCTAssertNil(match)
    }

    func testMatchesAudioByNormalizedTitleAndArtist() {
        let item = libraryItem(
            title: "小手拉大手",
            artist: "梁静茹",
            sourceURL: "https://www.youtube.com/watch?v=old",
            mode: .bestAudio
        )

        let match = DuplicateMediaMatcher.bestMatch(
            in: [item],
            lookup: DuplicateMediaLookup(
                sourceURL: nil,
                title: "小手 拉大手",
                artist: "梁靜茹",
                mode: .mp3
            )
        )

        XCTAssertEqual(match?.id, item.id)
    }

    func testTitleOnlyLookupDoesNotMatch() {
        let item = libraryItem(
            title: "江南",
            artist: "林俊杰",
            sourceURL: "https://www.youtube.com/watch?v=old",
            mode: .bestAudio
        )

        let match = DuplicateMediaMatcher.bestMatch(
            in: [item],
            lookup: DuplicateMediaLookup(
                sourceURL: nil,
                title: "江南",
                artist: nil,
                mode: .bestAudio
            )
        )

        XCTAssertNil(match)
    }

    private func libraryItem(title: String, artist: String?, sourceURL: String, mode: DownloadMode) -> LibraryMediaItem {
        LibraryMediaItem(
            id: UUID().uuidString,
            title: title,
            artist: artist,
            sourceURL: sourceURL,
            thumbnailURL: nil,
            filePath: "/tmp/\(UUID().uuidString).m4a",
            modeRawValue: mode.rawValue,
            addedAt: Date(),
            lastPlayedAt: nil,
            isFavorite: false
        )
    }
}
