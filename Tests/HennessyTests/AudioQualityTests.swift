import XCTest
@testable import Hennessy

final class AudioQualityTests: XCTestCase {
    func testParsesLowBitrateHEAAC() throws {
        let output = """
          Duration: 00:03:03.67, start: 0.000000, bitrate: 49 kb/s
          Stream #0:0: Audio: aac (HE-AAC), 44100 Hz, stereo, fltp, 48 kb/s
        """
        let quality = try AudioQualityParser.parse(ffmpegOutput: output, fileSize: 1_120_224)
        XCTAssertEqual(quality.codec, "aac")
        XCTAssertEqual(quality.profile, "HE-AAC")
        XCTAssertEqual(quality.sampleRate, 44_100)
        XCTAssertEqual(quality.channels, 2)
        XCTAssertEqual(quality.bitrate, 48_000)
        XCTAssertEqual(quality.tier, .needsImprovement)
    }

    func testUsesContainerBitrateForOpusWithoutStreamBitrate() throws {
        let output = """
          Duration: 00:04:46.14, start: 0.000000, bitrate: 149 kb/s
          Stream #0:0: Audio: opus, 48000 Hz, stereo, fltp
        """
        let quality = try AudioQualityParser.parse(ffmpegOutput: output, fileSize: 5_325_961)
        XCTAssertEqual(quality.codec, "opus")
        XCTAssertEqual(quality.bitrate, 149_000)
        XCTAssertEqual(quality.tier, .standard)
    }

    func testMP3IsDescribedAsTranscodedInsteadOfHighQuality() throws {
        let output = """
          Duration: 00:04:41.57, start: 0.025057, bitrate: 232 kb/s
          Stream #0:0: Audio: mp3, 44100 Hz, stereo, fltp, 232 kb/s
        """
        let quality = try AudioQualityParser.parse(ffmpegOutput: output, fileSize: 8_178_417)
        XCTAssertTrue(quality.isLikelyTranscoded)
        XCTAssertEqual(quality.qualityDescription, "MP3 二次转码 · 232 kbps")
    }

    func testReplacementRequiresThresholdAndMeaningfulGain() {
        let original = quality(codec: "aac", bitrate: 48_000)
        XCTAssertFalse(quality(codec: "opus", bitrate: 110_000).isMeaningfullyBetter(than: original))
        XCTAssertTrue(quality(codec: "opus", bitrate: 122_000).isMeaningfullyBetter(than: original))
        XCTAssertFalse(quality(codec: "mp3", bitrate: 232_000).isMeaningfullyBetter(than: original))
    }

    func testRemoteCandidateParsesYTDLPMetadata() {
        let candidate = RemoteAudioCandidate.parse(info: [
            "format_id": "251", "acodec": "opus", "abr": 145.875, "asr": 48_000
        ])
        XCTAssertEqual(candidate?.formatID, "251")
        XCTAssertEqual(candidate?.codec, "opus")
        XCTAssertEqual(candidate?.bitrate, 145_875)
        XCTAssertEqual(candidate?.sampleRate, 48_000)
        XCTAssertEqual(candidate?.isBelowImprovementThreshold, false)
    }

    func testRemoteCandidateNormalizesMP4AToAAC() {
        let candidate = RemoteAudioCandidate.parse(info: [
            "format_id": "140", "acodec": "mp4a.40.2", "abr": "128.0"
        ])
        XCTAssertEqual(candidate?.codec, "aac")
        XCTAssertEqual(candidate?.bitrate, 128_000)
    }

    func testLocalLibraryFilesWhenAvailable() async throws {
        let items = LibraryPersistence.load().filter { $0.isAudio && $0.existsOnDisk }
        guard !items.isEmpty else { throw XCTSkip("No local Hennessy library is available in this environment.") }
        let service = AudioQualityService()
        var failures: [String] = []
        for item in items {
            do {
                _ = try await service.inspect(fileURL: item.fileURL)
            } catch {
                failures.append("\(item.fileName): \(error.localizedDescription)")
            }
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    func testUpgradeInstallerKeepsRecoverableBackupAndUsesCandidateExtension() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("HennessyUpgradeTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let originalURL = root.appendingPathComponent("Track.m4a")
        let candidateURL = root.appendingPathComponent("Candidate.opus")
        try Data("original".utf8).write(to: originalURL)
        try Data("candidate".utf8).write(to: candidateURL)
        let item = LibraryMediaItem(
            id: originalURL.path,
            title: "Track",
            artist: "Artist",
            sourceURL: "https://example.com/track",
            thumbnailURL: nil,
            filePath: originalURL.path,
            modeRawValue: DownloadMode.mp3.rawValue,
            addedAt: .distantPast,
            lastPlayedAt: nil,
            isFavorite: true
        )
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let result = try AudioQualityUpgradeInstaller().install(item: item, candidateURL: candidateURL, now: now)
        XCTAssertEqual(result.replacement.fileURL.pathExtension, "opus")
        XCTAssertEqual(result.replacement.mode, .bestAudio)
        XCTAssertEqual(result.replacement.addedAt, now)
        XCTAssertTrue(result.replacement.isFavorite)
        XCTAssertEqual(try Data(contentsOf: result.replacement.fileURL), Data("candidate".utf8))
        XCTAssertEqual(try Data(contentsOf: result.backupURL), Data("original".utf8))
        XCTAssertTrue(result.backupURL.path.contains("Hennessy Quality Backups/20231114-221320"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: originalURL.path))
    }

    private func quality(codec: String, bitrate: Int) -> AudioQualityInfo {
        AudioQualityInfo(
            codec: codec,
            profile: nil,
            sampleRate: 48_000,
            channels: 2,
            bitrate: bitrate,
            duration: 180,
            fileSize: 1_000_000
        )
    }
}
