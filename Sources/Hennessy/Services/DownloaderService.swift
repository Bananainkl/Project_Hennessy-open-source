import Foundation

enum DownloaderError: LocalizedError {
    case missingDependency(String)
    case launchFailed(String)
    case commandFailed(String)
    case invalidMetadata(String)
    case missingOutputFile

    var errorDescription: String? {
        switch self {
        case .missingDependency(let name):
            "找不到依赖命令 \(name)。请重新安装最新版 Hennessy，或安装 Homebrew 后执行：brew install yt-dlp ffmpeg"
        case .launchFailed(let message):
            "无法启动下载进程：\(message)"
        case .commandFailed(let message):
            "命令执行失败：\(message)"
        case .invalidMetadata(let message):
            "无法解析媒体信息：\(message)"
        case .missingOutputFile:
            "下载完成后未找到媒体文件。可能该网页不含可提取音频/视频，或 ffmpeg 处理失败。"
        }
    }
}

final class DownloaderService: @unchecked Sendable {
    private let processLock = NSLock()
    private var activeProcess: Process?
    private let fileManager = FileManager.default
    private let audioQualityService = AudioQualityService()

    func cancel() {
        processLock.lock()
        defer { processLock.unlock() }
        activeProcess?.terminate()
        activeProcess = nil
    }

    func download(
        request: DownloadRequest,
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws -> DownloadResult {
        let directoryAccess = DirectoryAccess.startAccessing(request.outputDirectory)
        defer { directoryAccess.stop() }

        try await requireCommand("yt-dlp")
        try await requireCommand("ffmpeg")

        onOutput("开始下载，请稍等……\n")
        let info = try await mediaInfo(for: request.url, allowPlaylist: request.allowPlaylist, mode: request.mode)
        let metadata = MediaMetadata(info: info, titleOverride: request.titleOverride, artistOverride: request.artistOverride)
        if request.mode == .bestAudio || request.mode == .mp3,
           let candidate = RemoteAudioCandidate.parse(info: info) {
            onOutput("来源音质：\(candidate.description)\n")
            if candidate.isBelowImprovementThreshold {
                onOutput("提示：源站当前只提供低于 120 kbps 的音轨，文件不会因转码而获得更多细节。\n")
            }
        }

        try fileManager.createDirectory(at: request.outputDirectory, withIntermediateDirectories: true)
        let tempDirectory = try makeTemporaryDirectory()
        defer { try? fileManager.removeItem(at: tempDirectory) }

        let outputTemplate = tempDirectory.appendingPathComponent("media.%(ext)s").path
        var arguments = downloadArguments(for: request.mode, outputTemplate: outputTemplate)
        if !request.allowPlaylist {
            arguments.append("--no-playlist")
        }
        arguments.append(request.url)

        let downloadResult = try await runProcess(arguments: arguments, onOutput: onOutput)
        guard downloadResult.exitCode == 0 else {
            return downloadResult
        }

        let sourceURL = try newestMediaFile(in: tempDirectory, mode: request.mode)
        let finalURL: URL
        if request.mode == .videoMP4 {
            finalURL = try await convertToPlayableMP4(
                sourceURL: sourceURL,
                destinationURL: uniqueURL(request.outputDirectory.appendingPathComponent("\(metadata.fileStem).mp4")),
                onOutput: onOutput
            )
        } else {
            let destination = uniqueURL(request.outputDirectory.appendingPathComponent("\(metadata.fileStem).\(finalExtension(for: request.mode, sourceURL: sourceURL))"))
            try fileManager.moveItem(at: sourceURL, to: destination)
            finalURL = destination
        }

        onOutput("\(finalURL.path)\n")
        onOutput("下载完成：\(finalURL.path)\n")
        if request.mode == .bestAudio || request.mode == .mp3,
           let quality = try? await audioQualityService.inspect(fileURL: finalURL) {
            onOutput("文件核验：\(quality.qualityDescription)\n")
        }

        return DownloadResult(
            exitCode: 0,
            outputText: downloadResult.outputText + "\n\(finalURL.path)\n下载完成：\(finalURL.path)\n",
            errorText: downloadResult.errorText,
            thumbnailURL: metadata.thumbnailURL ?? request.thumbnailURL,
            songTitle: metadata.song,
            artistName: metadata.artist
        )
    }

    private func requireCommand(_ name: String) async throws {
        let result = try await runProcess(arguments: ["which", name], onOutput: nil)
        guard result.exitCode == 0 else {
            throw DownloaderError.missingDependency(name)
        }
    }

    private func mediaInfo(for url: String, allowPlaylist: Bool, mode: DownloadMode) async throws -> [String: Any] {
        var arguments = ["yt-dlp", "--dump-single-json", "--no-warnings", "-f", formatSelector(for: mode)]
        if !allowPlaylist {
            arguments.append("--no-playlist")
        }
        arguments.append(url)

        let result = try await runProcess(arguments: arguments, onOutput: nil)
        guard result.exitCode == 0 else {
            throw DownloaderError.commandFailed(result.errorText.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        guard let data = result.outputText.data(using: .utf8) else {
            throw DownloaderError.invalidMetadata("yt-dlp 没有返回可读取的数据。")
        }

        do {
            let object = try JSONSerialization.jsonObject(with: data)
            guard let info = object as? [String: Any] else {
                throw DownloaderError.invalidMetadata("返回值不是 JSON 对象。")
            }
            return info
        } catch let error as DownloaderError {
            throw error
        } catch {
            throw DownloaderError.invalidMetadata(error.localizedDescription)
        }
    }

    private func formatSelector(for mode: DownloadMode) -> String {
        switch mode {
        case .bestAudio, .mp3: "ba/b"
        case .video, .videoMP4: "bv*+ba/b"
        }
    }

    private func downloadArguments(for mode: DownloadMode, outputTemplate: String) -> [String] {
        switch mode {
        case .mp3:
            [
                "yt-dlp", "-f", "ba/b", "-x", "--audio-format", "mp3",
                "--audio-quality", "0", "--add-metadata", "-o", outputTemplate
            ]
        case .video:
            [
                "yt-dlp", "-f", "bv*+ba/b", "--merge-output-format", "mkv",
                "--add-metadata", "-o", outputTemplate
            ]
        case .videoMP4:
            [
                "yt-dlp", "-f", "bv*+ba/b", "--merge-output-format", "mkv",
                "--add-metadata", "-o", outputTemplate
            ]
        case .bestAudio:
            [
                "yt-dlp", "-f", "ba/b", "-x", "--audio-format", "best",
                "--audio-quality", "0", "--add-metadata", "-o", outputTemplate
            ]
        }
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("HennessyDownload-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func newestMediaFile(in directory: URL, mode: DownloadMode) throws -> URL {
        let urls = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        let candidates = urls.filter { url in
            let ext = url.pathExtension.lowercased()
            guard !["part", "ytdl", "json"].contains(ext) else { return false }
            if mode == .mp3 {
                return ext == "mp3"
            }
            return true
        }

        let sorted = try candidates.sorted { left, right in
            let leftDate = try left.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            let rightDate = try right.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? .distantPast
            return leftDate > rightDate
        }

        guard let newest = sorted.first else {
            throw DownloaderError.missingOutputFile
        }
        return newest
    }

    private func finalExtension(for mode: DownloadMode, sourceURL: URL) -> String {
        switch mode {
        case .mp3:
            "mp3"
        case .video:
            sourceURL.pathExtension.isEmpty ? "mkv" : sourceURL.pathExtension
        case .videoMP4:
            "mp4"
        case .bestAudio:
            sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        }
    }

    private func convertToPlayableMP4(
        sourceURL: URL,
        destinationURL: URL,
        onOutput: (@Sendable (String) -> Void)?
    ) async throws -> URL {
        let finalURL = uniqueURL(destinationURL)
        if try await isAVPlayerFriendlyMP4(sourceURL) {
            try fileManager.moveItem(at: sourceURL, to: finalURL)
            return finalURL
        }

        onOutput?("正在转换为播放器可直接播放的高质量 MP4……\n")
        let transcodingURL = finalURL.deletingPathExtension().appendingPathExtension("transcoding.mp4")
        try? fileManager.removeItem(at: transcodingURL)

        let result = try await runProcess(arguments: [
            "ffmpeg", "-y", "-i", sourceURL.path,
            "-map", "0:v:0", "-map", "0:a:0?",
            "-c:v", "libx264", "-preset", "slow", "-crf", "16",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "256k",
            "-movflags", "+faststart",
            transcodingURL.path
        ], onOutput: onOutput)

        guard result.exitCode == 0 else {
            throw DownloaderError.commandFailed(result.errorText.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        try fileManager.moveItem(at: transcodingURL, to: finalURL)
        return finalURL
    }

    private func isAVPlayerFriendlyMP4(_ url: URL) async throws -> Bool {
        guard url.pathExtension.lowercased() == "mp4" else { return false }
        let result = try await runProcess(arguments: [
            "ffprobe", "-v", "error", "-print_format", "json",
            "-show_streams", url.path
        ], onOutput: nil)
        guard result.exitCode == 0, let data = result.outputText.data(using: .utf8) else {
            return false
        }

        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let streams = object["streams"] as? [[String: Any]]
        else {
            return false
        }

        let videoCodec = streams.first { $0["codec_type"] as? String == "video" }?["codec_name"] as? String
        let audioCodec = streams.first { $0["codec_type"] as? String == "audio" }?["codec_name"] as? String
        return ["h264", "hevc"].contains(videoCodec ?? "")
            && (audioCodec == nil || ["aac", "alac", "mp3"].contains(audioCodec ?? ""))
    }

    private func uniqueURL(_ url: URL) -> URL {
        guard fileManager.fileExists(atPath: url.path) else { return url }
        let directory = url.deletingLastPathComponent()
        let stem = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var index = 2
        while true {
            let fileName = ext.isEmpty ? "\(stem) (\(index))" : "\(stem) (\(index)).\(ext)"
            let candidate = directory.appendingPathComponent(fileName)
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }

    private func runProcess(
        arguments: [String],
        onOutput: (@Sendable (String) -> Void)?
    ) async throws -> DownloadResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.environment = ProcessEnvironment.downloader

        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError

        let outputBuffer = OutputBuffer()
        let errorBuffer = OutputBuffer()

        return try await withCheckedThrowingContinuation { continuation in
            standardOutput.fileHandleForReading.readabilityHandler = { handle in
                let chunk = handle.availableData
                guard !chunk.isEmpty else { return }
                outputBuffer.append(chunk)
                if let text = String(data: chunk, encoding: .utf8), !text.isEmpty {
                    onOutput?(text)
                }
            }

            standardError.fileHandleForReading.readabilityHandler = { handle in
                let chunk = handle.availableData
                guard !chunk.isEmpty else { return }
                errorBuffer.append(chunk)
                if let text = String(data: chunk, encoding: .utf8), !text.isEmpty {
                    onOutput?(text)
                }
            }

            process.terminationHandler = { [weak self] finishedProcess in
                standardOutput.fileHandleForReading.readabilityHandler = nil
                standardError.fileHandleForReading.readabilityHandler = nil
                self?.processLock.lock()
                if self?.activeProcess === finishedProcess {
                    self?.activeProcess = nil
                }
                self?.processLock.unlock()

                continuation.resume(returning: DownloadResult(
                    exitCode: finishedProcess.terminationStatus,
                    outputText: outputBuffer.stringValue,
                    errorText: errorBuffer.stringValue,
                    thumbnailURL: nil,
                    songTitle: nil,
                    artistName: nil
                ))
            }

            do {
                processLock.lock()
                activeProcess = process
                processLock.unlock()
                try process.run()
            } catch {
                processLock.lock()
                activeProcess = nil
                processLock.unlock()
                continuation.resume(throwing: DownloaderError.launchFailed(error.localizedDescription))
            }
        }
    }
}

struct MediaMetadata {
    let song: String
    let artist: String
    let thumbnailURL: String?

    init(info: [String: Any], titleOverride: String, artistOverride: String) {
        let rawTitle = Self.stringValue(info["title"])
        let metadataArtists = [
            Self.stringValue(info["artist"]),
            Self.stringValue(info["artists"]),
            Self.stringValue(info["album_artist"]),
            Self.stringValue(info["creator"])
        ].filter { !$0.isEmpty && !Self.isSourceLikeArtist($0) }
        let sourceArtists = [
            Self.stringValue(info["uploader"]),
            Self.stringValue(info["channel"])
        ].filter { !$0.isEmpty && !Self.isSourceLikeArtist($0) }

        let parsed = Self.splitArtistTitle(rawTitle, knownArtists: metadataArtists + sourceArtists)
        let parsedSongCandidate = parsed.song.flatMap { candidate in
            Self.isUsableSongCandidate(candidate, parsed: parsed) ? candidate : nil
        }
        let trackCandidate = Self.cleanedSongCandidate(Self.stringValue(info["track"]))
        let altTitleCandidate = Self.cleanedSongCandidate(Self.stringValue(info["alt_title"]))
        let selectedMetadataArtist = metadataArtists.first { !Self.isLikelyWrongArtist($0, parsed: parsed) }
        song = Self.sanitize(
            titleOverride.isEmpty
                ? (Self.isUsableSongCandidate(trackCandidate, parsed: parsed) ? trackCandidate : nil)
                    ?? (Self.isUsableSongCandidate(altTitleCandidate, parsed: parsed) ? altTitleCandidate : nil)
                    ?? parsedSongCandidate
                    ?? Self.cleanedSongCandidate(rawTitle).nilIfEmpty
                    ?? Self.stringValue(info["id"]).nilIfEmpty
                    ?? "未知歌曲"
                : titleOverride,
            fallback: "未知歌曲"
        )
        artist = Self.sanitize(
            artistOverride.isEmpty
                ? selectedMetadataArtist
                    ?? parsed.artist
                    ?? sourceArtists.first
                    ?? "未知歌手"
                : artistOverride,
            fallback: "未知歌手"
        )
        thumbnailURL = Self.bestThumbnailURL(from: info)
    }

    var fileStem: String {
        "\(song)-\(artist)"
    }

    private static func stringValue(_ value: Any?) -> String {
        guard let value else { return "" }
        if let values = value as? [String] {
            return values.joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let values = value as? [Any] {
            return values.map { String(describing: $0) }.joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanedSongCandidate(_ value: String) -> String {
        stripCommonNoise(value).trimmingCharacters(in: separatorCharacters)
    }

    private static func isUsableSongCandidate(_ value: String, parsed: (artist: String?, song: String?)) -> Bool {
        let clean = value.trimmingCharacters(in: separatorCharacters)
        guard clean.count >= 2 else { return false }
        if isGenericNoiseTitle(clean) {
            return false
        }
        if let parsedArtist = parsed.artist, normalizedName(clean).contains(normalizedName(parsedArtist)) {
            return false
        }
        return true
    }

    private static func isLikelyWrongArtist(_ value: String, parsed: (artist: String?, song: String?)) -> Bool {
        let clean = value.trimmingCharacters(in: separatorCharacters)
        guard !clean.isEmpty else { return true }
        if isSourceLikeArtist(clean) {
            return true
        }
        if let song = parsed.song {
            let normalizedArtist = normalizedName(clean)
            let normalizedSong = normalizedName(song)
            if !normalizedSong.isEmpty, normalizedArtist.contains(normalizedSong) {
                return true
            }
        }
        return false
    }

    private static func isGenericNoiseTitle(_ value: String) -> Bool {
        value.range(
            of: #"^(歌词|歌詞|lyrics?|mv|music video|official|audio|完整版|官方版|动态歌词|動態歌詞)$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    private static func bestThumbnailURL(from info: [String: Any]) -> String? {
        if let thumbnails = info["thumbnails"] as? [[String: Any]] {
            let best = thumbnails
                .compactMap { thumb -> (url: String, score: Int)? in
                    let url = stringValue(thumb["url"])
                    guard !url.isEmpty else { return nil }
                    let width = Int(stringValue(thumb["width"])) ?? 0
                    let height = Int(stringValue(thumb["height"])) ?? 0
                    return (url, width * height)
                }
                .max { $0.score < $1.score }
            if let best {
                return best.url
            }
        }

        let thumbnail = stringValue(info["thumbnail"])
        return thumbnail.isEmpty ? nil : thumbnail
    }

    private static func sanitize(_ value: String, fallback: String) -> String {
        var clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.isEmpty {
            clean = fallback
        }
        let invalid = CharacterSet(charactersIn: #"<>:"/\|?*"#).union(.controlCharacters)
        clean = clean.components(separatedBy: invalid).joined(separator: "_")
        clean = clean.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        clean = clean.trimmingCharacters(in: CharacterSet(charactersIn: " ."))
        return clean.isEmpty ? fallback : clean
    }

    private static func splitArtistTitle(_ rawTitle: String, knownArtists: [String]) -> (artist: String?, song: String?) {
        let title = stripCommonNoise(rawTitle)

        for artist in knownArtists.sorted(by: { $0.count > $1.count }) {
            if title.lowercased().hasPrefix(artist.lowercased()) {
                let song = String(title.dropFirst(artist.count)).trimmingCharacters(in: separatorCharacters)
                if !song.isEmpty {
                    return (artist, song)
                }
            }
        }

        if let match = firstMatch(in: title, pattern: #"(.+?)[《<]([^》>]+)[》>]"#) {
            return (match[1], match[2])
        }

        if let match = firstMatch(in: title, pattern: #"[《<]([^》>]+)[》>](.+)"#) {
            let song = match[1]
            let artist = match[2].trimmingCharacters(in: separatorCharacters)
            return (artist.isEmpty ? nil : artist, song)
        }

        for separator in [" - ", " – ", " — ", "｜", "|", "-", "–", "—"] {
            guard title.contains(separator) else { continue }
            let parts = title.components(separatedBy: separator)
            guard parts.count >= 2 else { continue }
            let left = parts[0].trimmingCharacters(in: separatorCharacters)
            let right = parts.dropFirst().joined(separator: separator).trimmingCharacters(in: separatorCharacters)
            guard !left.isEmpty, !right.isEmpty else { continue }

            if matchesKnownArtist(left, knownArtists: knownArtists) {
                return (left, right)
            }
            if matchesKnownArtist(right, knownArtists: knownArtists) {
                return (right, left)
            }
            return (left, right)
        }

        if let inferred = splitCJKLatinArtistTitle(title) {
            return inferred
        }

        return (nil, title.isEmpty ? nil : title)
    }

    private static func stripCommonNoise(_ value: String) -> String {
        var title = value
        title = title.replacingOccurrences(of: #"\.(m4a|mp3|mp4|mkv|webm|aac|flac|wav)$"#, with: " ", options: [.regularExpression, .caseInsensitive])
        title = title.replacingOccurrences(
            of: #"\s+(官方完整版|官方完整版本|官方MV|官方版|官方音樂錄影帶|官方音乐录影带|官方|完整版|完整版本|official\s+music\s+video|official\s+mv|official\s+audio|official|music\s+video|mv).*$"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
        title = title.replacingOccurrences(
            of: #"\s*[-–—｜|]\s*[^-–—｜|]*(Taihe\s*Music|太合音樂|太合音乐|VEVO|Records|Recordings|Entertainment|Music|Official|精選|精选)[^-–—｜|]*"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
        title = title.replacingOccurrences(of: #"\[[^\]]*\]"#, with: " ", options: .regularExpression)
        title = title.replacingOccurrences(
            of: #"[《<][^》>]*(lyrics?|lyric|歌詞|歌词|動態歌詞|动态歌词|字幕)[^》>]*[》>]"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
        title = title.replacingOccurrences(of: #"[『「][^』」]{8,}[』」]"#, with: " ", options: .regularExpression)
        title = replacingFullWidthBrackets(in: title)
        title = title.replacingOccurrences(
            of: #"\([^)]*(official|mv|music video|lyrics|lyric|audio|cover|live|完整版|官方|歌词|動態歌詞|高音質)[^)]*\)"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
        title = title.replacingOccurrences(
            of: #"\b(official\s+music\s+video|official\s+mv|music\s+video|lyrics?\s+video|official|mv|hd|4k|8k)\b"#,
            with: " ",
            options: [.regularExpression, .caseInsensitive]
        )
        title = title.replacingOccurrences(of: #"#[\w\u{4e00}-\u{9fff}]+"#, with: " ", options: .regularExpression)
        title = title.replacingOccurrences(of: #"\s+(歌词|歌詞|动态歌词|動態歌詞)\s*$"#, with: " ", options: [.regularExpression, .caseInsensitive])
        title = title.replacingOccurrences(of: #"\s+(HD|HQ|4K|8K|1080P|720P)\s*$"#, with: " ", options: [.regularExpression, .caseInsensitive])
        title = title.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return title.trimmingCharacters(in: separatorCharacters)
    }

    private static func splitCJKLatinArtistTitle(_ title: String) -> (artist: String?, song: String?)? {
        let tokens = title.split(separator: " ").map(String.init)
        guard tokens.count >= 4 else { return nil }

        for index in 1..<(tokens.count - 1) {
            let currentIsLatin = tokens[index].range(of: #"[A-Za-z]"#, options: .regularExpression) != nil
            let nextHasCJK = tokens[index + 1].range(of: #"\p{Han}"#, options: .regularExpression) != nil
            guard currentIsLatin, nextHasCJK else { continue }

            let artist = tokens[0...index].joined(separator: " ").trimmingCharacters(in: separatorCharacters)
            let song = tokens[(index + 1)...].joined(separator: " ").trimmingCharacters(in: separatorCharacters)
            if artist.count >= 2, song.count >= 1 {
                return (artist, song)
            }
        }

        return nil
    }

    private static func isSourceLikeArtist(_ value: String) -> Bool {
        let normalized = value.lowercased()
        return normalized.range(
            of: #"(vevo|records|recordings|label|music|official|channel|娛樂|娱乐|音樂|音乐|唱片|太合|taihe|精選|精选)"#,
            options: .regularExpression
        ) != nil
    }

    private static func replacingFullWidthBrackets(in value: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"【([^】]*)】"#) else { return value }
        let nsValue = value as NSString
        let matches = regex.matches(in: value, range: NSRange(location: 0, length: nsValue.length)).reversed()
        var result = value

        for match in matches {
            guard let contentRange = Range(match.range(at: 1), in: value), let fullRange = Range(match.range, in: result) else {
                continue
            }
            let content = String(value[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let isNoise = content.range(
                of: #"(official|mv|music video|lyrics|lyric|audio|cover|live|完整版|官方|歌词|動態歌詞|动态歌词|高音質|高音质)"#,
                options: [.regularExpression, .caseInsensitive]
            ) != nil
            result.replaceSubrange(fullRange, with: isNoise ? " " : " \(content) ")
        }
        return result
    }

    private static func firstMatch(in value: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsValue = value as NSString
        guard let match = regex.firstMatch(in: value, range: NSRange(location: 0, length: nsValue.length)) else {
            return nil
        }
        return (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return "" }
            return nsValue.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func matchesKnownArtist(_ value: String, knownArtists: [String]) -> Bool {
        let normalizedValue = normalizedName(value)
        guard !normalizedValue.isEmpty else { return false }

        return knownArtists.contains { artist in
            let normalizedArtist = normalizedName(artist)
            return !normalizedArtist.isEmpty
                && (normalizedValue == normalizedArtist
                    || normalizedArtist.contains(normalizedValue)
                    || normalizedValue.contains(normalizedArtist))
        }
    }

    private static func normalizedName(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    private static var separatorCharacters: CharacterSet {
        CharacterSet(charactersIn: " -_｜|·")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private final class OutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    var stringValue: String {
        lock.lock()
        let value = String(data: data, encoding: .utf8) ?? ""
        lock.unlock()
        return value
    }
}
