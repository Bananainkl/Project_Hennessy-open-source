import Foundation

struct LibraryMediaItem: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var title: String
    var artist: String?
    var sourceURL: String
    var thumbnailURL: String?
    var sourceThumbnailURL: String?
    var filePath: String
    var modeRawValue: String
    var addedAt: Date
    var lastPlayedAt: Date?
    var isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case sourceURL
        case thumbnailURL
        case sourceThumbnailURL
        case filePath
        case modeRawValue
        case addedAt
        case lastPlayedAt
        case isFavorite
    }

    init(
        id: String,
        title: String,
        artist: String?,
        sourceURL: String,
        thumbnailURL: String?,
        sourceThumbnailURL: String? = nil,
        filePath: String,
        modeRawValue: String,
        addedAt: Date,
        lastPlayedAt: Date?,
        isFavorite: Bool
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.sourceURL = sourceURL
        self.thumbnailURL = thumbnailURL
        self.sourceThumbnailURL = sourceThumbnailURL
        self.filePath = filePath
        self.modeRawValue = modeRawValue
        self.addedAt = addedAt
        self.lastPlayedAt = lastPlayedAt
        self.isFavorite = isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decodeIfPresent(String.self, forKey: .artist)
        sourceURL = try container.decode(String.self, forKey: .sourceURL)
        thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)
        sourceThumbnailURL = try container.decodeIfPresent(String.self, forKey: .sourceThumbnailURL)
        filePath = try container.decode(String.self, forKey: .filePath)
        modeRawValue = try container.decode(String.self, forKey: .modeRawValue)
        addedAt = try container.decode(Date.self, forKey: .addedAt)
        lastPlayedAt = try container.decodeIfPresent(Date.self, forKey: .lastPlayedAt)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
    }

    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }

    var artworkURL: URL? {
        if let thumbnailURL, let url = URL(string: thumbnailURL) {
            return url
        }
        if let sourceThumbnailURL, let url = URL(string: sourceThumbnailURL) {
            return url
        }
        guard let videoID = Self.youtubeVideoID(from: sourceURL) else { return nil }
        return URL(string: "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg")
    }

    var sourceFallbackArtworkURL: URL? {
        if let sourceThumbnailURL, let url = URL(string: sourceThumbnailURL) {
            return url
        }
        guard let videoID = Self.youtubeVideoID(from: sourceURL) else { return nil }
        return URL(string: "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg")
    }

    var mode: DownloadMode {
        DownloadMode(rawValue: modeRawValue) ?? .bestAudio
    }

    var isAudio: Bool {
        mode == .bestAudio || mode == .mp3
    }

    var fileName: String {
        fileURL.lastPathComponent
    }

    var displayArtist: String {
        guard let artist, !artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return mediaKindText
        }
        return artist
    }

    var displaySubtitle: String {
        let artistText = artist?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return artistText.isEmpty ? fileName : artistText
    }

    var existsOnDisk: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    var mediaKindText: String {
        switch mode {
        case .bestAudio, .mp3:
            "音频"
        case .video, .videoMP4:
            "视频"
        }
    }

    private static func youtubeVideoID(from string: String) -> String? {
        guard let components = URLComponents(string: string) else { return nil }
        if components.host?.contains("youtu.be") == true {
            return components.path.split(separator: "/").first.map(String.init)
        }
        if components.host?.contains("youtube.com") == true {
            return components.queryItems?.first { $0.name == "v" }?.value
        }
        return nil
    }
}

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all
    case favorites

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "播放列表"
        case .favorites: "收藏"
        }
    }
}

enum PlaybackRepeatMode: String, CaseIterable, Identifiable {
    case none
    case all
    case one

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "顺序播放"
        case .all: "列表循环"
        case .one: "单曲循环"
        }
    }

    var icon: String {
        switch self {
        case .none: "arrow.right"
        case .all: "repeat"
        case .one: "repeat.1"
        }
    }
}
