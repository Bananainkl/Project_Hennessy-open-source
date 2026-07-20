import Foundation

enum ArtworkLookupError: LocalizedError {
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "专辑封面服务返回了无法读取的数据。"
        case .requestFailed(let statusCode):
            "专辑封面服务暂时不可用，状态码：\(statusCode)"
        }
    }
}

struct ArtworkLookupResult: Equatable, Sendable {
    let artworkURL: URL
    let matchedTitle: String
    let matchedArtist: String
    let confidence: Int
}

struct ArtworkSearchCandidate: Decodable, Equatable, Sendable {
    let trackName: String?
    let artistName: String?
    let collectionName: String?
    let artworkUrl100: String?
}

struct ArtworkMatchScore: Equatable, Sendable {
    let candidate: ArtworkSearchCandidate
    let value: Int
}

struct ArtworkMatchScorer: Sendable {
    static let automaticThresholdWithArtist = 64
    static let automaticThresholdWithoutArtist = 72

    let title: String
    let artist: String?

    func bestMatch(in candidates: [ArtworkSearchCandidate]) -> ArtworkMatchScore? {
        candidates
            .filter { $0.artworkUrl100?.isEmpty == false }
            .map { candidate in
                ArtworkMatchScore(candidate: candidate, value: score(candidate))
            }
            .filter { score in
                let threshold = cleanArtist.isEmpty
                    ? Self.automaticThresholdWithoutArtist
                    : Self.automaticThresholdWithArtist
                return score.value >= threshold
            }
            .max { left, right in
                left.value < right.value
            }
    }

    func score(_ candidate: ArtworkSearchCandidate) -> Int {
        let wantedTitle = Self.normalizedTitle(title)
        let candidateTitle = Self.normalizedTitle(candidate.trackName ?? "")
        let wantedArtist = Self.normalizedArtist(cleanArtist)
        let candidateArtist = Self.normalizedArtist(candidate.artistName ?? "")

        guard !wantedTitle.isEmpty, !candidateTitle.isEmpty else { return 0 }

        var score = titleScore(
            wantedTitle: wantedTitle,
            candidateTitle: candidateTitle,
            candidateOriginalTitle: candidate.trackName ?? ""
        )

        if wantedArtist.isEmpty {
            score += score >= 54 ? 18 : 0
        } else if candidateArtist == wantedArtist {
            score += 34
        } else if candidateArtist.contains(wantedArtist) || wantedArtist.contains(candidateArtist) {
            score += 28
        } else if Self.tokenOverlap(Self.artistTokens(cleanArtist), Self.artistTokens(candidate.artistName ?? "")) >= 0.55 {
            score += 18
        } else {
            score -= 30
        }

        if let collectionName = candidate.collectionName, !collectionName.isEmpty {
            let normalizedAlbum = Self.normalizedTitle(collectionName)
            if normalizedAlbum.contains(wantedTitle) {
                score += 4
            }
        }

        return score
    }

    static func highResolutionArtworkURL(from artworkURL: URL) -> URL {
        let value = artworkURL.absoluteString.replacingOccurrences(
            of: #"\d+x\d+bb"#,
            with: "600x600bb",
            options: .regularExpression
        )
        return URL(string: value) ?? artworkURL
    }

    static func normalizedTitle(_ value: String) -> String {
        normalized(
            value
                .replacingOccurrences(of: #"\([^)]*(official|lyrics?|mv|audio|video|cover|live|hd|4k)[^)]*\)"#, with: " ", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: #"（[^）]*(官方|歌詞|歌词|字幕|完整版|現場|现场|翻唱|伴奏)[^）]*）"#, with: " ", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: #"\[[^\]]*(official|lyrics?|mv|audio|video|cover|live|hd|4k)[^\]]*\]"#, with: " ", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: #"【[^】]*(官方|歌詞|歌词|字幕|完整版|現場|现场|翻唱|伴奏)[^】]*】"#, with: " ", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: #"《\s*(官方|歌詞|歌词|字幕|完整版|現場|现场|翻唱|伴奏)\s*》"#, with: " ", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: #"official|lyrics?|mv|music\s*video|audio|video|cover|live|hd|4k|topic|channel|官方|歌詞|歌词|字幕|完整版|純音樂|纯音乐"#, with: " ", options: [.regularExpression, .caseInsensitive])
        )
    }

    static func normalizedArtist(_ value: String) -> String {
        normalized(
            value
                .replacingOccurrences(of: #"\([^)]*\)|（[^）]*）"#, with: " ", options: .regularExpression)
                .replacingOccurrences(of: #"official|topic|channel|music|records?|lyrics?|歌詞|歌词|官方|音樂|音乐"#, with: " ", options: [.regularExpression, .caseInsensitive])
        )
    }

    private var cleanArtist: String {
        artist?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func titleScore(wantedTitle: String, candidateTitle: String, candidateOriginalTitle: String) -> Int {
        if candidateTitle == wantedTitle {
            return 58
        }
        if candidateTitle.contains(wantedTitle) || wantedTitle.contains(candidateTitle) {
            return 48
        }
        let overlap = Self.tokenOverlap(Self.titleTokens(title), Self.titleTokens(candidateOriginalTitle))
        if overlap >= 0.8 {
            return 42
        }
        if overlap >= 0.55 {
            return 28
        }
        return -34
    }

    private static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: #"&"#, with: "and")
            .replacingOccurrences(of: #"[()\[\]{}（）【】《》「」『』]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[\s\p{P}\p{S}]+"#, with: "", options: .regularExpression)
    }

    private static func titleTokens(_ value: String) -> [String] {
        tokenized(normalizedTitle(value))
    }

    private static func artistTokens(_ value: String) -> [String] {
        tokenized(normalizedArtist(value))
    }

    private static func tokenized(_ value: String) -> [String] {
        let latinTokens = value
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count >= 2 }
        if latinTokens.count > 1 {
            return latinTokens
        }
        return Array(value).map(String.init).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private static func tokenOverlap(_ left: [String], _ right: [String]) -> Double {
        guard !left.isEmpty, !right.isEmpty else { return 0 }
        let leftSet = Set(left)
        let rightSet = Set(right)
        let intersection = leftSet.intersection(rightSet).count
        return Double(intersection) / Double(min(leftSet.count, rightSet.count))
    }
}

final class ArtworkLookupService: Sendable {
    private struct ITunesSearchResponse: Decodable {
        let results: [ArtworkSearchCandidate]
    }

    private let session: URLSession
    private let countries = ["HK", "TW", "US", "CN"]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func lookupArtwork(title: String, artist: String?) async throws -> ArtworkLookupResult? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = artist?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return nil }

        let query = [cleanTitle, cleanArtist].compactMap { value -> String? in
            guard let value, !value.isEmpty else { return nil }
            return value
        }.joined(separator: " ")

        let scorer = ArtworkMatchScorer(title: cleanTitle, artist: cleanArtist)
        var bestScore: ArtworkMatchScore?

        for country in countries {
            let candidates = try await search(query: query, country: country)
            if let score = scorer.bestMatch(in: candidates), (bestScore == nil || score.value > bestScore!.value) {
                bestScore = score
            }
        }

        guard
            let bestScore,
            let artworkString = bestScore.candidate.artworkUrl100,
            let artworkURL = URL(string: artworkString)
        else {
            return nil
        }

        return ArtworkLookupResult(
            artworkURL: ArtworkMatchScorer.highResolutionArtworkURL(from: artworkURL),
            matchedTitle: bestScore.candidate.trackName ?? cleanTitle,
            matchedArtist: bestScore.candidate.artistName ?? cleanArtist ?? "",
            confidence: bestScore.value
        )
    }

    private func search(query: String, country: String) async throws -> [ArtworkSearchCandidate] {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "limit", value: "8"),
            URLQueryItem(name: "country", value: country)
        ]

        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ArtworkLookupError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ArtworkLookupError.requestFailed(httpResponse.statusCode)
        }
        return try JSONDecoder().decode(ITunesSearchResponse.self, from: data).results
    }
}
