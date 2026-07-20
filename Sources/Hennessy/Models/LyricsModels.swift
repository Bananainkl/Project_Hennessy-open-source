import Foundation

enum PlayerArtworkMode: String, Equatable, Sendable {
    case artwork
    case lyrics
}

enum LyricsLoadState: Equatable, Sendable {
    case idle
    case loading
    case available(LyricsTrack)
    case lowConfidence(LyricsTrack, reason: String)
    case unavailable(String)
    case failed(String)
}

struct LyricsTrack: Identifiable, Equatable, Sendable {
    let id: Int
    let trackName: String
    let artistName: String
    let albumName: String?
    let duration: TimeInterval?
    let plainLyrics: String?
    let syncedLines: [SyncedLyricLine]
    let providerName: String
    let confidence: Int

    var hasSyncedLyrics: Bool {
        !syncedLines.isEmpty
    }

    var hasPlainLyrics: Bool {
        plainLyrics?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    func activeLineIndex(at currentTime: TimeInterval) -> Int? {
        guard !syncedLines.isEmpty else { return nil }
        let time = max(0, currentTime)
        var low = 0
        var high = syncedLines.count - 1
        var best: Int?

        while low <= high {
            let mid = (low + high) / 2
            if syncedLines[mid].time <= time {
                best = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return best
    }
}

struct SyncedLyricLine: Identifiable, Equatable, Sendable {
    let id: Int
    let time: TimeInterval
    let text: String
}

struct LyricsParser {
    static func parseSyncedLyrics(_ value: String?) -> [SyncedLyricLine] {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let timestampPattern = #"\[(\d{1,3}):(\d{2})(?:[\.:](\d{1,3}))?\]"#
        guard let regex = try? NSRegularExpression(pattern: timestampPattern) else { return [] }

        var parsed: [(time: TimeInterval, text: String)] = []
        for rawLine in value.split(whereSeparator: \.isNewline) {
            let line = String(rawLine)
            let nsLine = line as NSString
            let fullRange = NSRange(location: 0, length: nsLine.length)
            let matches = regex.matches(in: line, range: fullRange)
            guard !matches.isEmpty else { continue }

            let lyricText = regex
                .stringByReplacingMatches(in: line, range: fullRange, withTemplate: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !lyricText.isEmpty else { continue }

            for match in matches {
                guard
                    let minuteRange = Range(match.range(at: 1), in: line),
                    let secondRange = Range(match.range(at: 2), in: line),
                    let minutes = Double(line[minuteRange]),
                    let seconds = Double(line[secondRange])
                else {
                    continue
                }

                var fraction = 0.0
                if
                    match.range(at: 3).location != NSNotFound,
                    let fractionRange = Range(match.range(at: 3), in: line)
                {
                    let rawFraction = String(line[fractionRange])
                    let divisor = pow(10.0, Double(rawFraction.count))
                    fraction = (Double(rawFraction) ?? 0) / divisor
                }

                parsed.append((minutes * 60 + seconds + fraction, lyricText))
            }
        }

        return parsed
            .sorted { $0.time < $1.time }
            .enumerated()
            .map { index, line in
                SyncedLyricLine(id: index, time: line.time, text: line.text)
            }
    }
}
