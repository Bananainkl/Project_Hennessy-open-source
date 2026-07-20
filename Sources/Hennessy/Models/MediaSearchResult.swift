import Foundation

struct MediaSearchResult: Identifiable, Equatable {
    let id: String
    let title: String
    let url: String
    let channel: String
    let duration: TimeInterval?
    let thumbnailURL: URL?

    var durationText: String {
        guard let duration, duration > 0 else { return "直播或未知时长" }
        let total = Int(duration.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
        }
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

struct CreatorSearchResult: Equatable {
    let creator: CreatorSearchCandidate
    let items: [MediaSearchResult]
}

struct CreatorSearchCandidate: Identifiable, Equatable {
    let id: String
    let title: String
    let url: String
    let handle: String?
    let followerCount: Int?
    let thumbnailURL: URL?
    let isVerified: Bool

    var subtitle: String {
        let handleText = handle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let followerText: String
        if let followerCount {
            followerText = Self.compactCount(followerCount)
        } else {
            followerText = ""
        }
        return [handleText, followerText].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private static func compactCount(_ value: Int) -> String {
        if value >= 10_000 {
            return "\(Double(value) / 10_000).formatted(.number.precision(.fractionLength(value >= 100_000 ? 0 : 1)))万订阅"
        }
        return "\(value) 订阅"
    }
}

struct RawMediaSearchResult: Decodable {
    struct Thumbnail: Decodable {
        let url: String?
        let width: Int?
        let height: Int?
    }

    let id: String?
    let title: String?
    let url: String?
    let webpageURL: String?
    let channel: String?
    let uploader: String?
    let duration: Double?
    let thumbnails: [Thumbnail]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case webpageURL = "webpage_url"
        case channel
        case uploader
        case duration
        case thumbnails
    }

    var result: MediaSearchResult? {
        guard let title, let resolvedURL else { return nil }
        let bestThumbnail = thumbnails?
            .compactMap { thumb -> (String, Int) in
                (thumb.url ?? "", (thumb.width ?? 0) * (thumb.height ?? 0))
            }
            .filter { !$0.0.isEmpty }
            .max { $0.1 < $1.1 }?
            .0

        return MediaSearchResult(
            id: id ?? resolvedURL,
            title: title,
            url: resolvedURL,
            channel: channel ?? uploader ?? "未知频道",
            duration: duration,
            thumbnailURL: bestThumbnail.flatMap(URL.init(string:))
        )
    }

    private var resolvedURL: String? {
        if let webpageURL, !webpageURL.isEmpty {
            return webpageURL
        }
        if let url, url.hasPrefix("http") {
            return url
        }
        if let id, !id.isEmpty {
            return "https://www.youtube.com/watch?v=\(id)"
        }
        return nil
    }
}
