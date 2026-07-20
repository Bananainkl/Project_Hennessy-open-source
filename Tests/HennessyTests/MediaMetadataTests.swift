import XCTest
@testable import Hennessy

final class MediaMetadataTests: XCTestCase {
    func testLyricsTitleIsNotUsedAsSongName() {
        let metadata = MediaMetadata(
            info: [
                "id": "abc123",
                "title": "梁静茹 - 小手拉大手《歌词》",
                "artist": "梁静茹 小手拉大手",
                "uploader": "璃之歌詞天地"
            ],
            titleOverride: "",
            artistOverride: ""
        )

        XCTAssertEqual(metadata.song, "小手拉大手")
        XCTAssertEqual(metadata.artist, "梁静茹")
        XCTAssertEqual(metadata.fileStem, "小手拉大手-梁静茹")
    }

    func testCJKLatinTitleSplitsIntoArtistAndSong() {
        let metadata = MediaMetadata(
            info: [
                "id": "jj-river-south",
                "title": "林俊傑 JJ Lin 江南 River South 官方完整版-太合音樂",
                "channel": "Taihe Music"
            ],
            titleOverride: "",
            artistOverride: ""
        )

        XCTAssertEqual(metadata.song, "江南 River South")
        XCTAssertEqual(metadata.artist, "林俊傑 JJ Lin")
    }
}
