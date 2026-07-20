import Foundation

enum LyricsLookupError: LocalizedError {
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "歌词服务返回了无法读取的数据。"
        case .requestFailed(let statusCode):
            "歌词服务暂时不可用，状态码：\(statusCode)"
        }
    }
}

struct LyricsSearchCandidate: Decodable, Equatable, Sendable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: TimeInterval?
    let instrumental: Bool?
    let plainLyrics: String?
    let syncedLyrics: String?

    var hasLyrics: Bool {
        plainLyrics?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || syncedLyrics?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var syncedLines: [SyncedLyricLine] {
        LyricsParser.parseSyncedLyrics(syncedLyrics)
    }

    func lyricsTrack(confidence: Int) -> LyricsTrack {
        LyricsTrack(
            id: id,
            trackName: trackName,
            artistName: artistName,
            albumName: albumName,
            duration: duration,
            plainLyrics: plainLyrics,
            syncedLines: syncedLines,
            providerName: "LRCLIB",
            confidence: confidence
        )
    }
}

struct LyricsLookupResult: Equatable, Sendable {
    let track: LyricsTrack?
    let isAutomaticMatch: Bool
    let reason: String

    static func unavailable(_ reason: String) -> LyricsLookupResult {
        LyricsLookupResult(track: nil, isAutomaticMatch: false, reason: reason)
    }
}

struct LyricsMatchScore: Equatable, Sendable {
    let candidate: LyricsSearchCandidate
    let value: Int
    let reason: String
}

struct LyricsMatchScorer: Sendable {
    static let automaticThreshold = 62
    static let reviewThreshold = 28

    let title: String
    let artist: String?
    let duration: TimeInterval?
    let isFallbackSearch: Bool

    func bestMatch(in candidates: [LyricsSearchCandidate]) -> LyricsMatchScore? {
        candidates
            .filter(\.hasLyrics)
            .map { candidate in
                LyricsMatchScore(candidate: candidate, value: score(candidate), reason: reason(for: candidate))
            }
            .max { left, right in
                if left.value != right.value {
                    return left.value < right.value
                }
                return left.candidate.syncedLines.count < right.candidate.syncedLines.count
            }
    }

    func score(_ candidate: LyricsSearchCandidate) -> Int {
        let wantedTitle = Self.normalized(title)
        let candidateTitle = Self.normalized(candidate.trackName)
        let wantedArtist = Self.normalized(artist ?? "")
        let candidateArtist = Self.normalized(candidate.artistName)

        var score = 0

        if !wantedTitle.isEmpty, candidateTitle == wantedTitle {
            score += 42
        } else if !wantedTitle.isEmpty, candidateTitle.contains(wantedTitle) || wantedTitle.contains(candidateTitle) {
            score += 28
        } else {
            score -= 34
        }

        if !wantedArtist.isEmpty {
            if candidateArtist == wantedArtist || candidateArtist.contains(wantedArtist) || wantedArtist.contains(candidateArtist) {
                score += 30
            } else if Self.artistTokens(artist ?? "").contains(where: { token in
                token.count >= 3 && candidateArtist.contains(token)
            }) {
                score += 16
            } else {
                score -= isFallbackSearch ? 18 : 26
            }
        }

        if let duration, duration > 30, let candidateDuration = candidate.duration, candidateDuration > 30 {
            let delta = abs(duration - candidateDuration)
            let tightWindow = max(2.5, duration * 0.025)
            let looseWindow = max(8, duration * 0.055)

            if delta <= tightWindow {
                score += 26
            } else if delta <= looseWindow {
                score += 12
            } else {
                score -= 18
            }
        }

        if candidate.syncedLines.isEmpty {
            score += candidate.plainLyrics == nil ? 0 : 4
        } else {
            score += 10
        }

        if candidate.instrumental == true {
            score -= 40
        }

        if isFallbackSearch {
            score -= 6
        }

        return score
    }

    private func reason(for candidate: LyricsSearchCandidate) -> String {
        let titleMatches = Self.normalized(candidate.trackName) == Self.normalized(title)
        let artistMatches = Self.normalized(artist ?? "").isEmpty
            || Self.normalized(candidate.artistName).contains(Self.normalized(artist ?? ""))
            || Self.normalized(artist ?? "").contains(Self.normalized(candidate.artistName))

        if titleMatches, artistMatches {
            return "歌名和歌手匹配"
        }
        if titleMatches {
            return "歌名匹配，但歌手或版本不够确定"
        }
        return "匹配结果不够确定"
    }

    static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: #"[()\[\]{}（）【】《》]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[\s\p{P}\p{S}]+"#, with: "", options: .regularExpression)
    }

    private static func artistTokens(_ value: String) -> [String] {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: #"\([^)]*\)|（[^）]*）"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"cover|covered\s*by|翻唱|topic|official|channel|music|station"#, with: " ", options: [.regularExpression, .caseInsensitive])
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { normalized(String($0)) }
            .filter { !$0.isEmpty }
    }
}

final class LyricsService: Sendable {
    private let session: URLSession
    private let baseURL = URL(string: "https://lrclib.net/api/search")!

    init(session: URLSession = .shared) {
        self.session = session
    }

    func lookup(for item: LibraryMediaItem, duration: TimeInterval?) async throws -> LyricsLookupResult {
        let cleanTitle = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = item.artist?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            return .unavailable("当前歌曲缺少可用于匹配的标题。")
        }

        var searchedCandidates: [LyricsSearchCandidate] = []

        if let cleanArtist, !cleanArtist.isEmpty {
            let strictCandidates = try await search(trackName: cleanTitle, artistName: cleanArtist)
            searchedCandidates.append(contentsOf: strictCandidates)

            if let best = LyricsMatchScorer(
                title: cleanTitle,
                artist: cleanArtist,
                duration: duration,
                isFallbackSearch: false
            ).bestMatch(in: strictCandidates) {
                if best.value >= LyricsMatchScorer.automaticThreshold {
                    return LyricsLookupResult(
                        track: best.candidate.lyricsTrack(confidence: best.value),
                        isAutomaticMatch: true,
                        reason: best.reason
                    )
                }
            }
        }

        let fallbackCandidates = try await search(trackName: cleanTitle, artistName: nil)
        searchedCandidates.append(contentsOf: fallbackCandidates)

        let best = LyricsMatchScorer(
            title: cleanTitle,
            artist: cleanArtist,
            duration: duration,
            isFallbackSearch: true
        ).bestMatch(in: uniqued(searchedCandidates))

        guard let best else {
            return .unavailable("没有找到这首歌的歌词。")
        }

        let track = best.candidate.lyricsTrack(confidence: best.value)
        if best.value >= LyricsMatchScorer.automaticThreshold {
            return LyricsLookupResult(track: track, isAutomaticMatch: true, reason: best.reason)
        }

        if best.value >= LyricsMatchScorer.reviewThreshold {
            return LyricsLookupResult(track: track, isAutomaticMatch: false, reason: best.reason)
        }

        return .unavailable("找到了相似结果，但置信度太低，已避免显示可能错误的歌词。")
    }

    private func search(trackName: String, artistName: String?) async throws -> [LyricsSearchCandidate] {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "track_name", value: trackName)
        ]
        if let artistName, !artistName.isEmpty {
            components?.queryItems?.append(URLQueryItem(name: "artist_name", value: artistName))
        }

        guard let url = components?.url else { throw LyricsLookupError.invalidResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Hennessy/1.7.0 (macOS lyrics lookup)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            throw LyricsLookupError.requestFailed(response.statusCode)
        }

        do {
            return try JSONDecoder().decode([LyricsSearchCandidate].self, from: data)
        } catch {
            throw LyricsLookupError.invalidResponse
        }
    }

    private func uniqued(_ candidates: [LyricsSearchCandidate]) -> [LyricsSearchCandidate] {
        var seen = Set<Int>()
        return candidates.filter { candidate in
            guard !seen.contains(candidate.id) else { return false }
            seen.insert(candidate.id)
            return true
        }
    }
}
