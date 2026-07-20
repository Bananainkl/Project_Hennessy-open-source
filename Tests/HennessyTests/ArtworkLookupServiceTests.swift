import XCTest
@testable import Hennessy

final class ArtworkLookupServiceTests: XCTestCase {
    func testArtworkScorerAcceptsMatchingTitleAndArtist() {
        let candidate = ArtworkSearchCandidate(
            trackName: "等一分钟 Wait One Minute",
            artistName: "徐誉滕 Xu Yu Teng",
            collectionName: "等一分钟",
            artworkUrl100: "https://is1-ssl.mzstatic.com/image/thumb/Music/aa/bb/cc/100x100bb.jpg"
        )

        let match = ArtworkMatchScorer(title: "等一分钟", artist: "徐誉滕").bestMatch(in: [candidate])

        XCTAssertNotNil(match)
        XCTAssertGreaterThanOrEqual(match?.value ?? 0, ArtworkMatchScorer.automaticThresholdWithArtist)
    }

    func testArtworkScorerRejectsWrongArtistWhenTitleMatches() {
        let candidate = ArtworkSearchCandidate(
            trackName: "月牙湾",
            artistName: "F.I.R.",
            collectionName: nil,
            artworkUrl100: "https://is1-ssl.mzstatic.com/image/thumb/Music/aa/bb/cc/100x100bb.jpg"
        )

        let match = ArtworkMatchScorer(title: "月牙湾", artist: "啊澈").bestMatch(in: [candidate])

        XCTAssertNil(match)
    }

    func testArtworkScorerStripsCommonVideoNoise() {
        let candidate = ArtworkSearchCandidate(
            trackName: "小手拉大手",
            artistName: "梁静茹",
            collectionName: nil,
            artworkUrl100: "https://is1-ssl.mzstatic.com/image/thumb/Music/aa/bb/cc/100x100bb.jpg"
        )

        let score = ArtworkMatchScorer(
            title: "梁静茹 - 小手拉大手《歌词》",
            artist: "梁静茹"
        ).score(candidate)

        XCTAssertGreaterThanOrEqual(score, ArtworkMatchScorer.automaticThresholdWithArtist)
    }

    func testHighResolutionArtworkURLUsesLargerArtwork() {
        let url = URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/aa/bb/cc/source/100x100bb.jpg")!

        let highResolution = ArtworkMatchScorer.highResolutionArtworkURL(from: url)

        XCTAssertTrue(highResolution.absoluteString.contains("600x600bb.jpg"))
    }

    func testLibraryArtworkFallsBackToSourceThumbnail() {
        let item = LibraryMediaItem(
            id: "song",
            title: "Song",
            artist: "Artist",
            sourceURL: "https://www.youtube.com/watch?v=abc123xyz",
            thumbnailURL: nil,
            sourceThumbnailURL: "https://i.ytimg.com/vi/abc123xyz/hqdefault.jpg",
            filePath: "/tmp/song.m4a",
            modeRawValue: DownloadMode.bestAudio.rawValue,
            addedAt: Date(),
            lastPlayedAt: nil,
            isFavorite: false
        )

        XCTAssertEqual(item.artworkURL?.absoluteString, "https://i.ytimg.com/vi/abc123xyz/hqdefault.jpg")
    }
}
