import Foundation

enum MediaSearchError: LocalizedError {
    case emptyQuery
    case launchFailed(String)
    case commandFailed(String)
    case noResults

    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            "请输入搜索关键词。"
        case .launchFailed(let message):
            "无法启动搜索进程：\(message)"
        case .commandFailed(let message):
            "搜索失败：\(message)"
        case .noResults:
            "没有找到可用结果。"
        }
    }
}

final class MediaSearchService: Sendable {
    func search(query: String, limit: Int = 80) async throws -> [MediaSearchResult] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { throw MediaSearchError.emptyQuery }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var combinedResults: [MediaSearchResult] = []
                var fallbackError: Error?
                let musicLimit = max(1, Int((Double(limit) * 0.60).rounded(.up)))
                let youtubeLimit = max(1, limit - musicLimit)

                do {
                    combinedResults.append(contentsOf: try self.runSearch(spec: .youtubeMusicSearchPage(cleanQuery), limit: musicLimit))
                } catch {
                    // Older yt-dlp builds or regional YouTube Music failures can make this
                    // command unavailable. Fall back to normal YouTube search below.
                    fallbackError = error
                }

                do {
                    combinedResults.append(contentsOf: try self.runSearch(spec: .youtubeSearch(cleanQuery), limit: youtubeLimit))
                    let results = self.uniqued(combinedResults).prefix(limit)
                    if results.isEmpty {
                        continuation.resume(throwing: MediaSearchError.noResults)
                    } else {
                        continuation.resume(returning: Array(results))
                    }
                } catch {
                    let results = self.uniqued(combinedResults).prefix(limit)
                    if results.isEmpty {
                        continuation.resume(throwing: fallbackError ?? error)
                    } else {
                        continuation.resume(returning: Array(results))
                    }
                }
            }
        }
    }

    func searchCreatorUploads(query: String, limit: Int = 100) async throws -> CreatorSearchResult {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { throw MediaSearchError.emptyQuery }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let channels = try self.runChannelSearch(query: cleanQuery, limit: 8)
                    guard let channel = CreatorChannelScorer(query: cleanQuery).bestMatch(in: channels) else {
                        throw MediaSearchError.noResults
                    }
                    let uploads = try self.runSearch(spec: .channelVideos(channel.url), limit: limit)
                    let items = self.uniqued(uploads).prefix(limit)
                    guard !items.isEmpty else {
                        throw MediaSearchError.noResults
                    }
                    continuation.resume(returning: CreatorSearchResult(creator: channel, items: Array(items)))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func uniqued(_ results: [MediaSearchResult]) -> [MediaSearchResult] {
        var seenIDs = Set<String>()
        var seenURLs = Set<String>()
        return results.filter { result in
            let videoID = URLComponents(string: result.url)?
                .queryItems?
                .first { $0.name == "v" }?
                .value ?? result.id
            let canonicalURL = result.url
                .replacingOccurrences(of: "https://music.youtube.com", with: "https://www.youtube.com")

            guard !seenIDs.contains(videoID), !seenURLs.contains(canonicalURL) else {
                return false
            }
            seenIDs.insert(videoID)
            seenURLs.insert(canonicalURL)
            return true
        }
    }

    private func runSearch(spec: SearchSpec, limit: Int) throws -> [MediaSearchResult] {
        let output = try runDumpJSON(input: spec.input(limit: limit), limit: limit)
        let decoder = JSONDecoder()
        return output
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> MediaSearchResult? in
                guard let data = String(line).data(using: .utf8) else { return nil }
                return try? decoder.decode(RawMediaSearchResult.self, from: data).result
            }
    }

    private func runChannelSearch(query: String, limit: Int) throws -> [CreatorSearchCandidate] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let channelSearchURL = "https://www.youtube.com/results?search_query=\(encodedQuery)&sp=EgIQAg%253D%253D"
        let output = try runDumpJSON(input: channelSearchURL, limit: limit)
        let decoder = JSONDecoder()
        return output
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> CreatorSearchCandidate? in
                guard let data = String(line).data(using: .utf8) else { return nil }
                return try? decoder.decode(RawCreatorChannelSearchResult.self, from: data).candidate
            }
    }

    private func runDumpJSON(input: String, limit: Int) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "yt-dlp",
            "--dump-json",
            "--flat-playlist",
            "--playlist-end",
            "\(limit)",
            input
        ]
        process.environment = ProcessEnvironment.downloader

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw MediaSearchError.launchFailed(error.localizedDescription)
        }

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw MediaSearchError.commandFailed(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return output
    }
}

private enum SearchSpec {
    case youtubeMusicSearchPage(String)
    case youtubeSearch(String)
    case channelVideos(String)

    func input(limit: Int) -> String {
        switch self {
        case .youtubeMusicSearchPage(let query):
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            return "https://music.youtube.com/search?q=\(encodedQuery)"
        case .youtubeSearch(let query):
            return "ytsearch\(limit):\(query)"
        case .channelVideos(let url):
            let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedURL.hasSuffix("/videos") else { return trimmedURL }
            return trimmedURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/videos"
        }
    }
}

struct CreatorChannelScorer: Sendable {
    let query: String

    func bestMatch(in candidates: [CreatorSearchCandidate]) -> CreatorSearchCandidate? {
        candidates
            .map { candidate in
                (candidate, score(candidate))
            }
            .filter { $0.1 >= 12 }
            .max { left, right in
                if left.1 != right.1 {
                    return left.1 < right.1
                }
                return (left.0.followerCount ?? 0) < (right.0.followerCount ?? 0)
            }?
            .0
    }

    func score(_ candidate: CreatorSearchCandidate) -> Int {
        let wanted = Self.normalized(query)
        let title = Self.normalized(candidate.title)
        let handle = Self.normalized(candidate.handle ?? "")
        guard !wanted.isEmpty else { return 0 }

        var score = 0
        if title == wanted || handle == wanted {
            score += 42
        } else if title.contains(wanted) || wanted.contains(title) || handle.contains(wanted) {
            score += 30
        } else {
            let overlap = max(
                Self.tokenOverlap(Self.tokens(query), Self.tokens(candidate.title)),
                Self.characterOverlap(wanted, title)
            )
            if overlap >= 0.55 {
                score += 18
            } else {
                score -= 18
            }
        }

        if candidate.isVerified {
            score += 14
        }
        if let followerCount = candidate.followerCount {
            if followerCount >= 1_000_000 {
                score += 12
            } else if followerCount >= 100_000 {
                score += 8
            } else if followerCount >= 10_000 {
                score += 4
            }
        }
        if candidate.title.range(of: #"fan\s*club|fans?|reaction|lyrics?|歌詞|歌词|粉絲|粉丝|搬運|搬运"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score -= 26
        }
        if candidate.title.range(of: #"topic"#, options: [.regularExpression, .caseInsensitive]) != nil {
            score += 2
        }
        return score
    }

    static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: #"[\s\p{P}\p{S}]+"#, with: "", options: .regularExpression)
    }

    private static func tokens(_ value: String) -> [String] {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { normalized(String($0)) }
            .filter { !$0.isEmpty }
    }

    private static func tokenOverlap(_ left: [String], _ right: [String]) -> Double {
        guard !left.isEmpty, !right.isEmpty else { return 0 }
        let leftSet = Set(left)
        let rightSet = Set(right)
        return Double(leftSet.intersection(rightSet).count) / Double(min(leftSet.count, rightSet.count))
    }

    private static func characterOverlap(_ left: String, _ right: String) -> Double {
        guard !left.isEmpty, !right.isEmpty else { return 0 }
        let leftSet = Set(left.map(String.init))
        let rightSet = Set(right.map(String.init))
        return Double(leftSet.intersection(rightSet).count) / Double(min(leftSet.count, rightSet.count))
    }
}

private struct RawCreatorChannelSearchResult: Decodable {
    let id: String?
    let title: String?
    let url: String?
    let channel: String?
    let uploader: String?
    let uploaderID: String?
    let uploaderURL: String?
    let channelURL: String?
    let channelFollowerCount: Int?
    let channelIsVerified: Bool?
    let thumbnails: [RawMediaSearchResult.Thumbnail]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case channel
        case uploader
        case uploaderID = "uploader_id"
        case uploaderURL = "uploader_url"
        case channelURL = "channel_url"
        case channelFollowerCount = "channel_follower_count"
        case channelIsVerified = "channel_is_verified"
        case thumbnails
    }

    var candidate: CreatorSearchCandidate? {
        guard let resolvedURL else { return nil }
        let title = title ?? channel ?? uploader ?? uploaderID ?? "未知创作者"
        let bestThumbnail = thumbnails?
            .compactMap { thumb -> (String, Int)? in
                guard let url = thumb.url, !url.isEmpty else { return nil }
                return (Self.normalizedThumbnailURL(url), (thumb.width ?? 0) * (thumb.height ?? 0))
            }
            .max { $0.1 < $1.1 }?
            .0

        return CreatorSearchCandidate(
            id: id ?? resolvedURL,
            title: title,
            url: resolvedURL,
            handle: uploaderID,
            followerCount: channelFollowerCount,
            thumbnailURL: bestThumbnail.flatMap(URL.init(string:)),
            isVerified: channelIsVerified == true
        )
    }

    private var resolvedURL: String? {
        if let channelURL, !channelURL.isEmpty {
            return channelURL
        }
        if let uploaderURL, !uploaderURL.isEmpty {
            return uploaderURL
        }
        if let url, url.hasPrefix("http") {
            return url
        }
        if let id, !id.isEmpty {
            return "https://www.youtube.com/channel/\(id)"
        }
        return nil
    }

    private static func normalizedThumbnailURL(_ value: String) -> String {
        if value.hasPrefix("//") {
            return "https:\(value)"
        }
        return value
    }
}
