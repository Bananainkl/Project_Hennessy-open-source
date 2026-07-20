import Foundation

struct DuplicateMediaLookup: Equatable {
    let sourceURL: String?
    let title: String?
    let artist: String?
    let mode: DownloadMode
}

enum DuplicateMediaMatcher {
    static func bestMatch(in items: [LibraryMediaItem], lookup: DuplicateMediaLookup) -> LibraryMediaItem? {
        let modeMatches = items.filter { item in
            isAudioMode(item.mode) == isAudioMode(lookup.mode)
        }

        if let sourceID = canonicalSourceID(lookup.sourceURL),
           let sourceMatch = modeMatches.first(where: { canonicalSourceID($0.sourceURL) == sourceID }) {
            return sourceMatch
        }

        guard isAudioMode(lookup.mode),
              let wantedTitle = normalizedText(lookup.title),
              let wantedArtist = normalizedText(lookup.artist),
              !wantedTitle.isEmpty,
              !wantedArtist.isEmpty else {
            return nil
        }

        return modeMatches.first { item in
            guard item.isAudio,
                  let itemArtist = normalizedText(item.artist),
                  !itemArtist.isEmpty else {
                return false
            }
            return normalizedText(item.title) == wantedTitle && itemArtist == wantedArtist
        }
    }

    static func canonicalSourceID(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        guard var components = URLComponents(string: value),
              let host = components.host?.lowercased() else {
            return normalizedPlainURL(value)
        }

        if let youtubeID = youtubeVideoID(from: components, host: host) {
            return "youtube:\(youtubeID)"
        }

        components.scheme = components.scheme?.lowercased()
        components.host = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        components.fragment = nil
        components.path = normalizedPath(components.path)
        components.queryItems = normalizedQueryItems(components.queryItems)

        return components.url?.absoluteString ?? normalizedPlainURL(value)
    }

    static func normalizedText(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        let simplified = value.applyingTransform(StringTransform(rawValue: "Hant-Hans"), reverse: false) ?? value

        return simplified
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: #"[\s\p{P}\p{S}]+"#, with: "", options: .regularExpression)
    }

    private static func youtubeVideoID(from components: URLComponents, host: String) -> String? {
        guard host.contains("youtube.com")
            || host.contains("youtu.be")
            || host.contains("youtube-nocookie.com") else {
            return nil
        }

        if host.contains("youtu.be") {
            return components.path.split(separator: "/").first.map(String.init)
        }

        if let queryID = components.queryItems?.first(where: { $0.name == "v" })?.value,
           !queryID.isEmpty {
            return queryID
        }

        let pathParts = components.path.split(separator: "/").map(String.init)
        if let markerIndex = pathParts.firstIndex(where: { ["shorts", "embed", "live"].contains($0) }),
           pathParts.indices.contains(markerIndex + 1) {
            return pathParts[markerIndex + 1]
        }

        return nil
    }

    private static func normalizedPath(_ path: String) -> String {
        guard path.count > 1 else { return path }
        var normalized = path
        while normalized.count > 1 && normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return normalized
    }

    private static func normalizedQueryItems(_ items: [URLQueryItem]?) -> [URLQueryItem]? {
        let filtered = (items ?? []).filter { item in
            let name = item.name.lowercased()
            return !name.hasPrefix("utm_") && name != "feature" && name != "si"
        }
        guard !filtered.isEmpty else { return nil }
        return filtered.sorted {
            if $0.name != $1.name {
                return $0.name < $1.name
            }
            return ($0.value ?? "") < ($1.value ?? "")
        }
    }

    private static func normalizedPlainURL(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
    }

    private static func isAudioMode(_ mode: DownloadMode) -> Bool {
        mode == .bestAudio || mode == .mp3
    }
}
