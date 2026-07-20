import XCTest
@testable import Hennessy

final class CreatorSearchTests: XCTestCase {
    func testCreatorScorerPrefersVerifiedOfficialChannelOverFanChannel() {
        let official = CreatorSearchCandidate(
            id: "official",
            title: "GEM鄧紫棋",
            url: "https://www.youtube.com/channel/official",
            handle: "@gem0816",
            followerCount: 2_900_000,
            thumbnailURL: nil,
            isVerified: true
        )
        let fanClub = CreatorSearchCandidate(
            id: "fan",
            title: "GEM鄧紫棋 HK Fans Club",
            url: "https://www.youtube.com/channel/fan",
            handle: "@gemhkfansclub",
            followerCount: 103_000,
            thumbnailURL: nil,
            isVerified: false
        )

        let match = CreatorChannelScorer(query: "G.E.M. 邓紫棋").bestMatch(in: [fanClub, official])

        XCTAssertEqual(match, official)
    }

    func testCreatorScorerRejectsUnrelatedChannel() {
        let unrelated = CreatorSearchCandidate(
            id: "other",
            title: "Random Covers",
            url: "https://www.youtube.com/channel/other",
            handle: "@covers",
            followerCount: 2_000_000,
            thumbnailURL: nil,
            isVerified: true
        )

        let match = CreatorChannelScorer(query: "梁静茹").bestMatch(in: [unrelated])

        XCTAssertNil(match)
    }
}
