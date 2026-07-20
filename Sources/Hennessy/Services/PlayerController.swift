import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class PlayerController {
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var currentEnergy: Double = 0
    var visualPhase: Double = 0
    var volume: Double = 0.75
    var crossfadeLeadTime: Double?

    @ObservationIgnored
    private let player = AVPlayer()
    @ObservationIgnored
    private var loadedItemID: String?
    @ObservationIgnored
    private var timeObserver: Any?
    @ObservationIgnored
    private var endObserver: NSObjectProtocol?
    @ObservationIgnored
    private var energyProfile: AudioEnergyProfile?
    @ObservationIgnored
    private var analysisTask: Task<Void, Never>?
    @ObservationIgnored
    private var fadeTransitionTask: Task<Void, Never>?
    @ObservationIgnored
    private var crossfadeRequestedItemID: String?
    @ObservationIgnored
    private var lastPlaybackTime: Double = 0
    @ObservationIgnored
    private var didReachPlaybackEnd = false
    @ObservationIgnored
    var onPlaybackEnded: (() -> Void)?
    @ObservationIgnored
    var onCrossfadeRequested: (() -> Void)?

    var avPlayer: AVPlayer {
        player
    }

    var currentItemID: String? {
        loadedItemID
    }

    init() {
        player.volume = Float(volume)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.05, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                let playbackTime = time.seconds.isFinite ? time.seconds : 0
                let isCurrentlyPlaying = self.player.timeControlStatus == .playing
                self.currentTime = playbackTime
                if let duration = self.player.currentItem?.duration.seconds, duration.isFinite {
                    self.duration = duration
                }
                self.isPlaying = isCurrentlyPlaying
                let targetEnergy = self.energyProfile?.energy(at: self.currentTime) ?? (self.isPlaying ? 0.22 : 0)
                self.currentEnergy = self.smoothedEnergy(current: self.currentEnergy, target: targetEnergy)
                if isCurrentlyPlaying {
                    let delta = max(0, min(0.12, playbackTime - self.lastPlaybackTime))
                    self.visualPhase += delta * (0.55 + 2.75 * self.currentEnergy)
                }
                self.requestCrossfadeIfNeeded(isCurrentlyPlaying: isCurrentlyPlaying)
                self.lastPlaybackTime = playbackTime
            }
        }
    }

    deinit {
        MainActor.assumeIsolated {
            player.pause()
            if let timeObserver {
                player.removeTimeObserver(timeObserver)
            }
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            analysisTask?.cancel()
            fadeTransitionTask?.cancel()
            player.replaceCurrentItem(with: nil)
        }
    }

    func load(_ item: LibraryMediaItem, autoplay: Bool) {
        guard item.existsOnDisk else {
            pause()
            player.replaceCurrentItem(with: nil)
            loadedItemID = nil
            currentTime = 0
            duration = 0
            currentEnergy = 0
            visualPhase = 0
            lastPlaybackTime = 0
            energyProfile = nil
            analysisTask?.cancel()
            return
        }
        guard loadedItemID != item.id else {
            if autoplay { startPlayback() }
            return
        }

        pause()
        loadedItemID = item.id
        currentTime = 0
        duration = 0
        currentEnergy = 0
        visualPhase = 0
        lastPlaybackTime = 0
        didReachPlaybackEnd = false
        crossfadeRequestedItemID = nil
        energyProfile = nil
        analysisTask?.cancel()
        let asset = AVURLAsset(url: item.fileURL)
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)
        installEndObserver(for: playerItem)
        analyzeEnergy(for: item)

        if autoplay {
            startPlayback()
        }
    }

    func loadWithFade(_ item: LibraryMediaItem, autoplay: Bool, fadeDuration: TimeInterval = 0.62) {
        guard loadedItemID != nil, loadedItemID != item.id, isPlaying else {
            load(item, autoplay: autoplay)
            return
        }

        fadeTransitionTask?.cancel()
        fadeTransitionTask = Task { @MainActor in
            await fadePlayerVolume(to: 0, duration: fadeDuration * 0.44)
            guard !Task.isCancelled else { return }

            load(item, autoplay: autoplay)
            player.volume = 0

            guard autoplay, !Task.isCancelled else {
                player.volume = Float(volume)
                return
            }

            await fadePlayerVolume(to: volume, duration: fadeDuration * 0.56)
            guard !Task.isCancelled else { return }
            player.volume = Float(volume)
        }
    }

    func togglePlayPause(_ item: LibraryMediaItem) {
        if loadedItemID != item.id {
            load(item, autoplay: true)
            return
        }
        if player.timeControlStatus == .playing {
            pause()
        } else {
            startPlayback()
        }
    }

    func restart(_ item: LibraryMediaItem) {
        if loadedItemID != item.id {
            load(item, autoplay: true)
            return
        }
        didReachPlaybackEnd = true
        startPlayback()
    }

    func seek(to seconds: Double) {
        guard seconds.isFinite else { return }
        let clampedSeconds = duration > 0 ? max(0, min(seconds, duration)) : max(0, seconds)
        let target = CMTime(seconds: clampedSeconds, preferredTimescale: 600)

        player.currentItem?.cancelPendingSeeks()
        currentTime = clampedSeconds
        currentEnergy = energyProfile?.energy(at: clampedSeconds) ?? (isPlaying ? 0.22 : 0)
        lastPlaybackTime = clampedSeconds
        if duration <= 0 || clampedSeconds < duration - 0.2 {
            didReachPlaybackEnd = false
        }

        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard finished else { return }
            Task { @MainActor in
                guard let self else { return }
                let actualTime = self.player.currentTime().seconds
                if actualTime.isFinite {
                    self.currentTime = actualTime
                    self.lastPlaybackTime = actualTime
                }
            }
        }
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func setVolume(_ value: Double) {
        let clamped = max(0, min(1, value))
        volume = clamped
        player.volume = Float(clamped)
    }

    private func installEndObserver(for playerItem: AVPlayerItem) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isPlaying = false
                self.currentEnergy = 0
                self.didReachPlaybackEnd = true
                self.onPlaybackEnded?()
            }
        }
    }

    private func startPlayback() {
        if PlaybackResumePolicy.shouldRestart(
            didReachEnd: didReachPlaybackEnd,
            currentTime: currentTime,
            duration: duration
        ) {
            didReachPlaybackEnd = false
            currentTime = 0
            lastPlaybackTime = 0
            currentEnergy = energyProfile?.energy(at: 0) ?? 0.22
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        player.play()
        isPlaying = true
    }

    private func analyzeEnergy(for item: LibraryMediaItem) {
        let itemID = item.id
        let url = item.fileURL

        analysisTask = Task { [weak self] in
            let profile = await Task.detached(priority: .utility) {
                AudioEnergyAnalyzer.analyze(url: url)
            }.value

            await MainActor.run {
                guard let self, self.loadedItemID == itemID, !Task.isCancelled else { return }
                self.energyProfile = profile
                self.currentEnergy = profile?.energy(at: self.currentTime) ?? (self.isPlaying ? 0.22 : 0)
            }
        }
    }

    private func smoothedEnergy(current: Double, target: Double) -> Double {
        let attack = target > current ? 0.18 : 0.08
        return current + (target - current) * attack
    }

    private func fadePlayerVolume(to targetVolume: Double, duration: TimeInterval) async {
        let target = max(0, min(1, targetVolume))
        let start = Double(player.volume)
        let steps = max(1, Int(duration / 0.025))
        let interval = max(0.005, duration / Double(steps))

        for step in 1...steps {
            guard !Task.isCancelled else { return }
            let progress = Double(step) / Double(steps)
            let eased = progress * progress * (3 - 2 * progress)
            player.volume = Float(start + (target - start) * eased)
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }

        player.volume = Float(target)
    }

    private func requestCrossfadeIfNeeded(isCurrentlyPlaying: Bool) {
        guard isCurrentlyPlaying,
              let leadTime = crossfadeLeadTime,
              leadTime > 0,
              let itemID = loadedItemID,
              crossfadeRequestedItemID != itemID,
              duration.isFinite,
              duration > leadTime + 1,
              currentTime >= duration - leadTime
        else {
            return
        }

        crossfadeRequestedItemID = itemID
        onCrossfadeRequested?()
    }
}

enum PlaybackResumePolicy {
    static func shouldRestart(didReachEnd: Bool, currentTime: Double, duration: Double) -> Bool {
        guard !didReachEnd else { return true }
        guard currentTime.isFinite, duration.isFinite, duration > 0 else { return false }
        return currentTime >= duration - 0.2
    }
}
