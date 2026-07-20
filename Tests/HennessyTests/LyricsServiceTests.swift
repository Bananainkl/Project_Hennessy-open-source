import XCTest
@testable import Hennessy

final class LyricsServiceTests: XCTestCase {
    func testSyncedLyricsParserExtractsTimestampedLines() {
        let lines = LyricsParser.parseSyncedLyrics("""
        [00:01.20]first line
        [00:03.450]second line
        [01:02]third line
        """)

        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].time, 1.2, accuracy: 0.001)
        XCTAssertEqual(lines[0].text, "first line")
        XCTAssertEqual(lines[1].time, 3.45, accuracy: 0.001)
        XCTAssertEqual(lines[2].time, 62, accuracy: 0.001)
    }

    func testLyricsScorerAcceptsExactTitleAndArtist() {
        let candidate = LyricsSearchCandidate(
            id: 1,
            trackName: "等一分钟 Wait One Minute",
            artistName: "徐誉滕 Xu Yu Teng",
            albumName: "Teng Love",
            duration: 241,
            instrumental: false,
            plainLyrics: "plain",
            syncedLyrics: "[00:01.00]line"
        )

        let score = LyricsMatchScorer(
            title: "等一分钟",
            artist: "徐誉滕 Xu Yu Teng",
            duration: 241,
            isFallbackSearch: false
        ).score(candidate)

        XCTAssertGreaterThanOrEqual(score, LyricsMatchScorer.automaticThreshold)
    }

    func testLyricsScorerKeepsTranslatedTitleInsideParentheses() {
        let candidate = LyricsSearchCandidate(
            id: 3,
            trackName: "El Viejo y El Mar (老人与海)",
            artistName: "G.E.M.邓紫棋",
            albumName: nil,
            duration: 193,
            instrumental: false,
            plainLyrics: "plain",
            syncedLyrics: "[00:01.00]line"
        )

        let score = LyricsMatchScorer(
            title: "老人与海",
            artist: "G.E.M",
            duration: nil,
            isFallbackSearch: false
        ).score(candidate)

        XCTAssertGreaterThanOrEqual(score, LyricsMatchScorer.automaticThreshold)
    }

    func testLyricsScorerRequiresReviewWhenOnlyTitleMatches() {
        let candidate = LyricsSearchCandidate(
            id: 2,
            trackName: "月牙湾",
            artistName: "F.I.R.",
            albumName: nil,
            duration: 306,
            instrumental: false,
            plainLyrics: "plain",
            syncedLyrics: "[00:01.00]line"
        )

        let score = LyricsMatchScorer(
            title: "月牙湾",
            artist: "啊澈",
            duration: nil,
            isFallbackSearch: true
        ).score(candidate)

        XCTAssertGreaterThanOrEqual(score, LyricsMatchScorer.reviewThreshold)
        XCTAssertLessThan(score, LyricsMatchScorer.automaticThreshold)
    }
}
