import XCTest
@testable import Hennessy

final class PlaylistDownloadPlannerTests: XCTestCase {
    func testPlaylistEntryParsesArtistTitleAndURLRows() {
        let entries = PlaylistDownloadEntry.entries(from: """
        1. 梁静茹 - 小手拉大手
        https://www.youtube.com/watch?v=abc123 林俊傑 - 江南
        """)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].artist, "梁静茹")
        XCTAssertEqual(entries[0].title, "小手拉大手")
        XCTAssertEqual(entries[0].searchQuery, "梁静茹 小手拉大手")
        XCTAssertEqual(entries[1].url, "https://www.youtube.com/watch?v=abc123")
        XCTAssertEqual(entries[1].artist, "林俊傑")
        XCTAssertEqual(entries[1].title, "江南")
    }

    func testPlaylistScorerPrefersOfficialArtistChannelOverLyricAndTVResults() throws {
        let entry = try XCTUnwrap(PlaylistDownloadEntry(rawLine: "梁静茹 - 小手拉大手"))
        let results = [
            result(id: "generic", title: "梁靜茹-小手拉大手", channel: "a26755776", duration: 275),
            result(id: "lyric", title: "梁靜茹 小手拉大手《歌詞》", channel: "璃之歌詞天地", duration: 245),
            result(id: "official", title: "小手拉大手", channel: "梁靜茹 Fish Leong", duration: 247),
            result(id: "tv", title: "小手拉大手 LIVE 现场版", channel: "江苏卫视", duration: 360)
        ]

        let scorer = PlaylistMatchScorer(mode: .bestAudio)
        let best = try XCTUnwrap(scorer.bestMatch(for: entry, in: results))

        XCTAssertEqual(best.result.id, "official")
        XCTAssertGreaterThan(scorer.score(results[2], entry: entry), scorer.score(results[0], entry: entry))
        XCTAssertLessThan(scorer.score(results[1], entry: entry), 0)
        XCTAssertLessThan(scorer.score(results[3], entry: entry), PlaylistMatchScorer.minimumAcceptableScore)
    }

    private func result(id: String, title: String, channel: String, duration: TimeInterval?) -> MediaSearchResult {
        MediaSearchResult(
            id: id,
            title: title,
            url: "https://www.youtube.com/watch?v=\(id)",
            channel: channel,
            duration: duration,
            thumbnailURL: nil
        )
    }
}
