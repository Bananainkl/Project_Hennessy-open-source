import Foundation

enum AudioQualityTier: String, Sendable {
    case needsImprovement
    case standard
    case highBitrate

    var title: String {
        switch self {
        case .needsImprovement: "需改善"
        case .standard: "普通"
        case .highBitrate: "高码率"
        }
    }
}

struct AudioQualityInfo: Equatable, Sendable {
    static let improvementThreshold = 120_000

    let codec: String
    let profile: String?
    let sampleRate: Int
    let channels: Int?
    let bitrate: Int
    let duration: Double
    let fileSize: Int64

    var tier: AudioQualityTier {
        if bitrate < Self.improvementThreshold { return .needsImprovement }
        return bitrate < 192_000 ? .standard : .highBitrate
    }

    var isLikelyTranscoded: Bool { codec.lowercased() == "mp3" }

    var codecDisplayName: String {
        let normalizedCodec = codec.uppercased()
        guard let profile, !profile.isEmpty else { return normalizedCodec }
        return "\(normalizedCodec) \(profile)"
    }

    var bitrateKbps: Int { Int((Double(bitrate) / 1_000).rounded()) }
    var compactDescription: String { "\(codecDisplayName) · \(bitrateKbps) kbps" }

    var qualityDescription: String {
        if isLikelyTranscoded { return "MP3 二次转码 · \(bitrateKbps) kbps" }
        return "\(tier.title) · \(compactDescription)"
    }

    func isMeaningfullyBetter(than original: AudioQualityInfo) -> Bool {
        guard !isLikelyTranscoded, bitrate >= Self.improvementThreshold else { return false }
        let minimumGain = max(16_000, Int((Double(original.bitrate) * 0.20).rounded()))
        return bitrate >= original.bitrate + minimumGain
    }
}

struct RemoteAudioCandidate: Equatable, Sendable {
    let formatID: String
    let codec: String
    let bitrate: Int?
    let sampleRate: Int?

    var description: String {
        var parts = ["格式 \(formatID)", codec.uppercased()]
        if let bitrate { parts.append("\(Int((Double(bitrate) / 1_000).rounded())) kbps") }
        if let sampleRate { parts.append("\(sampleRate / 1_000) kHz") }
        return parts.joined(separator: " · ")
    }

    var isBelowImprovementThreshold: Bool {
        guard let bitrate else { return false }
        return bitrate < AudioQualityInfo.improvementThreshold
    }

    static func parse(info: [String: Any]) -> RemoteAudioCandidate? {
        let formatID = stringValue(info["format_id"])
        let rawCodec = stringValue(info["acodec"])
        guard !formatID.isEmpty, !rawCodec.isEmpty, rawCodec != "none" else { return nil }
        let codec = rawCodec.lowercased().hasPrefix("mp4a") ? "aac" : (rawCodec.components(separatedBy: ".").first ?? rawCodec)
        return RemoteAudioCandidate(
            formatID: formatID,
            codec: codec,
            bitrate: numberValue(info["abr"] ?? info["tbr"]).map { Int(($0 * 1_000).rounded()) },
            sampleRate: numberValue(info["asr"]).map { Int($0.rounded()) }
        )
    }

    private static func stringValue(_ value: Any?) -> String {
        guard let value else { return "" }
        return String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func numberValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        return Double(stringValue(value))
    }
}

enum AudioQualityParseError: LocalizedError {
    case missingAudioStream
    case missingDuration

    var errorDescription: String? {
        switch self {
        case .missingAudioStream: "文件中没有可识别的音频轨道。"
        case .missingDuration: "无法读取音频时长。"
        }
    }
}

enum AudioQualityParser {
    static func parse(ffmpegOutput: String, fileSize: Int64) throws -> AudioQualityInfo {
        guard let audioLine = ffmpegOutput
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .first(where: { $0.contains("Audio:") })
        else { throw AudioQualityParseError.missingAudioStream }

        guard let durationMatch = firstMatch(in: ffmpegOutput, pattern: #"Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)"#),
              durationMatch.count == 4,
              let hours = Double(durationMatch[1]),
              let minutes = Double(durationMatch[2]),
              let seconds = Double(durationMatch[3])
        else { throw AudioQualityParseError.missingDuration }

        let duration = hours * 3_600 + minutes * 60 + seconds
        guard duration > 0 else { throw AudioQualityParseError.missingDuration }
        let codecField = firstMatch(in: audioLine, pattern: #"Audio:\s*([^,]+)"#)?[1]
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
        let codec = codecField.split(separator: " ").first.map(String.init) ?? codecField
        let profile = firstMatch(in: codecField, pattern: #"\(([^)]+)\)"#)?.dropFirst().first
        let sampleRate = firstMatch(in: audioLine, pattern: #"(\d+)\s*Hz"#).flatMap { Int($0[1]) } ?? 0
        let channels: Int?
        if audioLine.range(of: #"\bmono\b"#, options: .regularExpression) != nil {
            channels = 1
        } else if audioLine.range(of: #"\bstereo\b"#, options: .regularExpression) != nil {
            channels = 2
        } else {
            channels = nil
        }
        let streamBitrate = firstMatch(in: audioLine, pattern: #"(\d+(?:\.\d+)?)\s*kb/s"#)
            .flatMap { Double($0[1]) }.map { Int(($0 * 1_000).rounded()) }
        let containerBitrate = firstMatch(in: ffmpegOutput, pattern: #"bitrate:\s*(\d+(?:\.\d+)?)\s*kb/s"#)
            .flatMap { Double($0[1]) }.map { Int(($0 * 1_000).rounded()) }
        let calculatedBitrate = Int((Double(fileSize) * 8 / duration).rounded())
        return AudioQualityInfo(
            codec: codec,
            profile: profile,
            sampleRate: sampleRate,
            channels: channels,
            bitrate: streamBitrate ?? containerBitrate ?? calculatedBitrate,
            duration: duration,
            fileSize: fileSize
        )
    }

    private static func firstMatch(in value: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsValue = value as NSString
        guard let match = regex.firstMatch(in: value, range: NSRange(location: 0, length: nsValue.length)) else { return nil }
        return (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return "" }
            return nsValue.substring(with: range)
        }
    }
}
