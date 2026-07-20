import Foundation

struct PlaylistDownloadEntry: Equatable {
    let rawLine: String
    let url: String?
    let title: String?
    let artist: String?
    let thumbnailURL: String?
    let displayTitle: String?

    init?(rawLine: String) {
        let normalized = Self.cleanLine(rawLine)
        guard !normalized.isEmpty else { return nil }
        self.rawLine = normalized
        thumbnailURL = nil
        displayTitle = nil

        if let url = Self.firstURL(in: normalized) {
            self.url = url
            let remainder = normalized
                .replacingOccurrences(of: url, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let parsed = Self.parseArtistTitle(remainder)
            title = parsed.title
            artist = parsed.artist
            return
        }

        url = nil
        let parsed = Self.parseArtistTitle(normalized)
        title = parsed.title
        artist = parsed.artist
    }

    init(mediaResult: MediaSearchResult) {
        rawLine = mediaResult.url
        url = mediaResult.url
        title = nil
        artist = nil
        thumbnailURL = mediaResult.thumbnailURL?.absoluteString
        displayTitle = mediaResult.title
    }

    static func entries(from text: String) -> [PlaylistDownloadEntry] {
        text.split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(PlaylistDownloadEntry.init(rawLine:))
    }

    var searchQuery: String {
        let query = [artist, title]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? rawLine : query
    }

    var displayName: String {
        if let displayTitle, !displayTitle.isEmpty {
            return displayTitle
        }
        if let artist, let title {
            return "\(artist) - \(title)"
        }
        return rawLine
    }

    private static func cleanLine(_ line: String) -> String {
        var value = line.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: #"^\s*(\d+[\.\)、)]|\-|\*|•)\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstURL(in line: String) -> String? {
        line.split(separator: " ").map(String.init).first { part in
            URL(string: part)?.scheme?.hasPrefix("http") == true
        }
    }

    private static func parseArtistTitle(_ value: String) -> (artist: String?, title: String?) {
        guard !value.isEmpty else { return (nil, nil) }
        for separator in [" - ", " – ", " — ", "｜", "|", "\t"] {
            guard value.contains(separator) else { continue }
            let parts = value.components(separatedBy: separator)
            guard parts.count >= 2 else { continue }
            let left = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let right = parts.dropFirst().joined(separator: separator).trimmingCharacters(in: .whitespacesAndNewlines)
            if !left.isEmpty, !right.isEmpty {
                return (left, right)
            }
        }
        return (nil, value)
    }
}

struct PlaylistDownloadProgressItem: Identifiable, Equatable {
    let id: Int
    let entry: PlaylistDownloadEntry
    var state: PlaylistDownloadProgressState
    var detail: String
}

enum PlaylistDownloadProgressState: String, Equatable {
    case pending
    case searching
    case matched
    case downloading
    case duplicate
    case done
    case failed

    var title: String {
        switch self {
        case .pending: "等待"
        case .searching: "搜索"
        case .matched: "已匹配"
        case .downloading: "下载"
        case .duplicate: "已存在"
        case .done: "完成"
        case .failed: "失败"
        }
    }
}

struct PlaylistDownloadMatch: Equatable {
    let result: MediaSearchResult
    let score: Int
}

struct PlaylistMatchScorer {
    static let minimumAcceptableScore = 12

    let mode: DownloadMode

    func bestMatch(for entry: PlaylistDownloadEntry, in results: [MediaSearchResult]) -> PlaylistDownloadMatch? {
        results
            .map { PlaylistDownloadMatch(result: $0, score: score($0, entry: entry)) }
            .max { left, right in
                if left.score != right.score {
                    return left.score < right.score
                }
                return tieBreakerScore(left.result, entry: entry) < tieBreakerScore(right.result, entry: entry)
            }
    }

    func score(_ result: MediaSearchResult, entry: PlaylistDownloadEntry) -> Int {
        let titleText = result.title
        let channelText = result.channel
        let normalizedTitle = Self.normalized(titleText)
        let normalizedChannel = Self.normalized(channelText)
        let combined = "\(titleText) \(channelText)"

        var score = 0
        var matchedTitle = false
        var matchedArtist = false

        if let wantedTitle = entry.title.map(Self.normalized), !wantedTitle.isEmpty {
            if normalizedTitle == wantedTitle {
                score += 18
                matchedTitle = true
            } else if normalizedTitle.contains(wantedTitle) {
                score += 13
                matchedTitle = true
            } else if wantedTitle.contains(normalizedTitle), normalizedTitle.count >= 3 {
                score += 6
                matchedTitle = true
            } else {
                score -= 12
            }

            if matchedTitle, normalizedTitle.count <= wantedTitle.count + 8 {
                score += 4
            }
        }

        if let wantedArtist = entry.artist.map(Self.normalized), !wantedArtist.isEmpty {
            if normalizedChannel.contains(wantedArtist) {
                score += 18
                matchedArtist = true
            }
            if normalizedTitle.contains(wantedArtist) {
                score += 8
                matchedArtist = true
            }
            if !matchedArtist {
                score -= 4
            }
        }

        if matchedTitle, matchedArtist {
            score += 8
        }

        score += sourceQualityScore(title: titleText, channel: channelText, combined: combined, matchedTitle: matchedTitle)
        score += durationScore(result.duration)
        return score
    }

    private func tieBreakerScore(_ result: MediaSearchResult, entry: PlaylistDownloadEntry) -> Int {
        var score = 0
        let normalizedTitle = Self.normalized(result.title)
        if let wantedTitle = entry.title.map(Self.normalized), normalizedTitle == wantedTitle {
            score += 10
        }
        if result.duration != nil {
            score += 2
        }
        if result.channel.range(of: "topic|official|vevo|auto-generated|官方", options: [.regularExpression, .caseInsensitive]) != nil {
            score += 3
        }
        return score
    }

    private func sourceQualityScore(title: String, channel: String, combined: String, matchedTitle: Bool) -> Int {
        var score = 0
        let titleLower = title.lowercased()
        let channelLower = channel.lowercased()
        let combinedLower = combined.lowercased()

        if titleLower.range(of: #"lyrics?|lyric\s+video|歌詞|歌词|動態歌詞|动态歌词|字幕"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score -= 35
        }
        if titleLower.range(of: #"cover|翻唱|karaoke|伴奏|instrumental|piano\s+cover"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score -= 24
        }
        if combinedLower.range(of: #"reaction|tutorial|lesson|教学|教學|解析|解說|解说"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score -= 20
        }
        if combinedLower.range(of: #"live|concert|performance|演唱會|演唱会|現場|现场|飯拍|饭拍"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score -= isVideoMode ? 8 : 18
        }
        if combinedLower.range(of: #"mangotv|湖南卫视|湖南衛視|江苏卫视|江蘇衛視|综艺|綜藝|tv|television"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score -= 24
        }
        if combinedLower.range(of: #"playlist|合集|合輯|mix|hour|loop|循环|循環"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score -= 14
        }

        if matchedTitle, channelLower.range(of: #"topic|auto-generated|official artist channel|vevo"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score += 10
        }
        if titleLower.range(of: #"official\s+audio|官方音频|官方音訊|官方音源"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score += 10
        }
        if titleLower.range(of: #"official\s+music\s+video|official\s+mv|官方mv|官方音樂錄影帶|官方音乐录影带"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score += isVideoMode ? 10 : 2
        }
        if matchedTitle, titleLower.range(of: #"lyrics?|歌詞|歌词|cover|翻唱|live|演唱會|演唱会"#, options: [.regularExpression, .caseInsensitive]) == nil {
            score += 3
        }

        return score
    }

    private func durationScore(_ duration: TimeInterval?) -> Int {
        guard let duration, duration > 0 else { return -2 }
        if isVideoMode {
            if (90...600).contains(duration) { return 3 }
            if duration < 45 || duration > 1_200 { return -10 }
            return 0
        }

        if (120...480).contains(duration) { return 4 }
        if duration < 60 || duration > 900 { return -12 }
        return 0
    }

    private var isVideoMode: Bool {
        mode == .video || mode == .videoMP4
    }

    static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: #"[\s\p{P}\p{S}]+"#, with: "", options: .regularExpression)
    }
}
