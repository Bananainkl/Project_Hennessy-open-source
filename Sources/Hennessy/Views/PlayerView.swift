import AVKit
import AppKit
import SwiftUI

struct PlayerView: View {
    @Bindable var store: DownloadStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            libraryContent
        }
        .onAppear {
            loadSelectedItemIfNeeded()
        }
        .onChange(of: store.selectedLibraryItemID) {
            loadSelectedItemIfNeeded()
        }
    }

    private var libraryContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("播放列表")
                        .font(HennessyDesign.Typography.pageTitle)
                        .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                    Text("\(store.visibleLibraryItems.count) 项媒体")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                }

                Spacer()

                Button {
                    store.refreshAllAlbumArtwork()
                } label: {
                    Label(store.isArtworkRefreshRunning ? "刷新中" : "刷新封面", systemImage: "arrow.triangle.2.circlepath")
                }
                .albumArtworkRefreshButtonStyle(isActive: store.isArtworkRefreshRunning)
                .disabled(store.isArtworkRefreshRunning || !store.hasRefreshableArtworkItems)
                .help(store.hasRefreshableArtworkItems ? "重新匹配所有音频的专辑封面，失败时退回源站封面" : "暂无可刷新的音频")

                LibraryFilterTabs(selection: $store.libraryFilter)
                    .frame(width: 232)
            }
            .padding(.horizontal, HennessyDesign.Spacing.contentHorizontal)
            .padding(.top, HennessyDesign.Spacing.contentTop)

            if store.visibleLibraryItems.isEmpty {
                ContentUnavailableView(
                    store.libraryFilter == .favorites ? "暂无收藏" : "暂无媒体",
                    systemImage: store.libraryFilter == .favorites ? "heart" : "music.note.list",
                    description: Text("下载完成的音频和视频会出现在这里。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, HennessyDesign.Spacing.miniPlayerReserved)
            } else {
                MediaListView(
                    items: store.visibleLibraryItems,
                    selectedID: store.selectedLibraryItemID,
                    select: { store.selectLibraryItem($0) },
                    toggleFavorite: { store.toggleFavorite($0) },
                    refreshArtwork: { store.refreshArtwork(for: $0) },
                    edit: { store.beginEditingLibraryItem($0) },
                    reveal: { store.revealLibraryItem($0) },
                    remove: { store.removeFromLibrary($0) }
                )
                .padding(.horizontal, HennessyDesign.Spacing.contentHorizontal)
            }
        }
        .appleMusicWindowBackground()
    }

    private func loadSelectedItemIfNeeded() {
        store.playSelectedLibraryItemIfNeeded()
    }
}

struct RecentPlayedView: View {
    @Bindable var store: DownloadStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 5) {
                Text("最近播放")
                    .font(HennessyDesign.Typography.pageTitle)
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                Text("\(store.recentlyPlayedItems.count) 项媒体")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
            }
            .padding(.horizontal, HennessyDesign.Spacing.contentHorizontal)
            .padding(.top, HennessyDesign.Spacing.contentTop)

            if store.recentlyPlayedItems.isEmpty {
                ContentUnavailableView("暂无最近播放", systemImage: "clock", description: Text("播放过的音乐和视频会出现在这里。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, HennessyDesign.Spacing.miniPlayerReserved)
            } else {
                MediaListView(
                    items: store.recentlyPlayedItems,
                    selectedID: store.selectedLibraryItemID,
                    select: { store.selectLibraryItem($0) },
                    toggleFavorite: { store.toggleFavorite($0) },
                    refreshArtwork: { store.refreshArtwork(for: $0) },
                    edit: { store.beginEditingLibraryItem($0) },
                    reveal: { store.revealLibraryItem($0) },
                    remove: { store.removeFromLibrary($0) }
                )
                .padding(.horizontal, HennessyDesign.Spacing.contentHorizontal)
            }
        }
        .appleMusicWindowBackground()
    }
}

struct FullPlayerView: View {
    @Bindable var store: DownloadStore
    let reduceMotion: Bool

    var body: some View {
        PlayerWindow(store: store, reduceMotion: reduceMotion)
    }
}

private typealias PlayerDesign = HennessyDesign.Player

private struct PlayerWindow: View {
    @Bindable var store: DownloadStore
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let metrics = PlayerLayoutMetrics(size: proxy.size)
            ZStack {
                FullPlayerBackdrop()

                VStack(spacing: 0) {
                    PlayerTopControls(store: store)
                        .frame(height: PlayerDesign.Layout.topBarHeight)
                        .padding(.horizontal, PlayerDesign.Layout.horizontalInset)

                    PlayerBody(store: store, reduceMotion: reduceMotion, metrics: metrics)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .font(.system(.body, design: .default))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

private struct PlayerLayoutMetrics {
    let size: CGSize

    var bodyHorizontalPadding: CGFloat {
        size.width < 1200 ? 44 : 64
    }

    var bodyTopPadding: CGFloat {
        size.height < 820 ? 8 : 16
    }

    var bodyBottomPadding: CGFloat {
        size.height < 820 ? 30 : 48
    }

    var bodyHeight: CGFloat {
        max(540, size.height - PlayerDesign.Layout.topBarHeight)
    }

    var availableBodyHeight: CGFloat {
        max(440, bodyHeight - bodyTopPadding - bodyBottomPadding)
    }

    var contentWidth: CGFloat {
        max(680, size.width - bodyHorizontalPadding * 2)
    }

    var columnGap: CGFloat {
        if size.width < 1120 {
            return 40
        }
        return min(max(64, size.width * 0.052), 92)
    }

    var leftColumnWidth: CGFloat {
        let columnsWidth = max(620, contentWidth - columnGap)
        return min(max(columnsWidth * 0.47, 320), 520)
    }

    var rightColumnWidth: CGFloat {
        let columnsWidth = max(620, contentWidth - columnGap)
        return min(max(columnsWidth - leftColumnWidth, 360), 620)
    }

    var artworkSize: CGFloat {
        let reservedHeight = trackInfoHeight + progressHeight + controlsHeight + infoGap + progressGap + controlsGap
        let heightBound = max(220, availableBodyHeight - reservedHeight)
        let widthBound = leftColumnWidth
        let preferred = min(widthBound, heightBound)
        return min(max(preferred, size.height < 820 ? 220 : 260), size.height < 820 ? 300 : 360)
    }

    var trackInfoHeight: CGFloat {
        size.height < 820 ? 74 : 88
    }

    var progressHeight: CGFloat {
        34
    }

    var controlsHeight: CGFloat {
        size.height < 820 ? 48 : 54
    }

    var controlButtonSize: CGFloat {
        if artworkSize < 300 {
            return 30
        }
        return artworkSize < 330 ? 34 : 40
    }

    var prominentControlButtonSize: CGFloat {
        if artworkSize < 300 {
            return 38
        }
        return artworkSize < 330 ? 44 : 50
    }

    var controlSpacing: CGFloat {
        let buttonTotal = controlButtonSize * 4 + prominentControlButtonSize
        let availableSpacing = (artworkSize - buttonTotal) / 4
        return min(max(availableSpacing, 10), 34)
    }

    var smallControlIconSize: CGFloat {
        if artworkSize < 300 {
            return 16
        }
        return artworkSize < 330 ? 18 : 20
    }

    var skipControlIconSize: CGFloat {
        if artworkSize < 300 {
            return 21
        }
        return artworkSize < 330 ? 25 : 29
    }

    var playControlIconSize: CGFloat {
        if artworkSize < 300 {
            return 27
        }
        return artworkSize < 330 ? 31 : 36
    }

    var infoGap: CGFloat {
        size.height < 820 ? 18 : 26
    }

    var progressGap: CGFloat {
        size.height < 820 ? 24 : 32
    }

    var controlsGap: CGFloat {
        size.height < 820 ? 28 : 36
    }

    var nowPlayingTopOffset: CGFloat {
        size.height < 820 ? 46 : 64
    }

    var queueHeaderGap: CGFloat {
        size.height < 820 ? 30 : 44
    }

    var queueHeight: CGFloat {
        availableBodyHeight
    }
}

private struct PlayerBody: View {
    @Bindable var store: DownloadStore
    let reduceMotion: Bool
    let metrics: PlayerLayoutMetrics

    var body: some View {
        HStack(alignment: .top, spacing: metrics.columnGap) {
            NowPlayingPanel(store: store, item: store.selectedLibraryItem, reduceMotion: reduceMotion, metrics: metrics)
                .frame(width: metrics.leftColumnWidth, height: metrics.availableBodyHeight, alignment: .top)

            QueuePanel(store: store, currentItem: store.selectedLibraryItem, metrics: metrics)
                .frame(width: metrics.rightColumnWidth, height: metrics.availableBodyHeight, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, metrics.bodyHorizontalPadding)
        .padding(.top, metrics.bodyTopPadding)
        .padding(.bottom, metrics.bodyBottomPadding)
    }
}

private struct PlayerTopControls: View {
    @Bindable var store: DownloadStore

    var body: some View {
        HStack(alignment: .top) {
            HStack(spacing: 0) {
                Button {
                    withAnimation(.smooth(duration: 0.26)) {
                        store.isFullPlayerPresented = false
                    }
                } label: {
                    Image(systemName: "chevron.down")
                }
                .appleMusicTopIconButton()
                .help("返回小播放器")

                Rectangle()
                    .fill(PlayerDesign.ColorToken.separator.opacity(0.46))
                    .frame(width: 0.7, height: 22)

                Button {
                    withAnimation(.smooth(duration: 0.26)) {
                        store.isFullPlayerPresented = false
                    }
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                }
                .appleMusicTopIconButton()
                .help("返回播放列表")
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(PlayerDesign.ColorToken.glassStrong.opacity(0.82), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
            }

            Spacer()

            HStack(spacing: 12) {
                Slider(
                    value: Binding(
                        get: { store.playerController.volume },
                        set: { store.playerController.setVolume($0) }
                    ),
                    in: 0...1
                )
                .tint(PlayerDesign.ColorToken.accent)
                .frame(width: 150)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PlayerDesign.ColorToken.textPrimary)
            }
            .frame(width: 208, height: 36)
            .background(PlayerDesign.ColorToken.glassStrong.opacity(0.82), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
            }
        }
        .padding(.top, PlayerDesign.Layout.topInset)
    }
}

private struct NowPlayingPanel: View {
    @Bindable var store: DownloadStore
    let item: LibraryMediaItem?
    let reduceMotion: Bool
    let metrics: PlayerLayoutMetrics

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if let item {
                AlbumArtwork(store: store, item: item, reduceMotion: reduceMotion)
                    .frame(width: metrics.artworkSize, height: metrics.artworkSize)
                    .padding(.bottom, metrics.infoGap)

                TrackInfo(item: item)
                    .frame(height: metrics.trackInfoHeight, alignment: .top)
                    .frame(width: metrics.artworkSize, alignment: .leading)
                    .padding(.bottom, metrics.progressGap)

                ProgressBar(
                    currentTime: store.playerController.currentTime,
                    duration: store.playerController.duration,
                    seek: { store.playerController.seek(to: $0) }
                )
                .frame(height: metrics.progressHeight)
                .frame(width: metrics.artworkSize)
                .padding(.bottom, metrics.controlsGap)

                PlaybackControls(store: store, item: item, metrics: metrics)
                    .frame(height: metrics.controlsHeight)
                    .frame(width: metrics.artworkSize)
            } else {
                AlbumArtwork(store: store, item: nil, reduceMotion: reduceMotion)
                    .frame(width: metrics.artworkSize, height: metrics.artworkSize)
                    .padding(.bottom, metrics.infoGap)

                TrackInfo(item: nil)
                    .frame(height: metrics.trackInfoHeight, alignment: .top)
                    .frame(width: metrics.artworkSize, alignment: .leading)
                    .padding(.bottom, metrics.progressGap)

                ProgressBar(currentTime: 0, duration: 0, seek: { _ in })
                    .frame(height: metrics.progressHeight)
                    .frame(width: metrics.artworkSize)
                    .padding(.bottom, metrics.controlsGap)

                PlaybackControls(store: store, item: nil, metrics: metrics)
                    .frame(height: metrics.controlsHeight)
                    .frame(width: metrics.artworkSize)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, metrics.nowPlayingTopOffset)
        .clipped()
    }
}

private struct AlbumArtwork: View {
    @Bindable var store: DownloadStore
    let item: LibraryMediaItem?
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)

            Group {
                if let item {
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if store.playerArtworkMode == .lyrics {
                                LyricsArtworkPanel(
                                    store: store,
                                    item: item,
                                    currentTime: store.playerController.currentTime
                                )
                                .transition(.opacity)
                                .onAppear {
                                    store.loadLyricsForSelectedItemIfNeeded()
                                }
                                .onChange(of: item.id) { _, _ in
                                    store.loadLyricsForSelectedItemIfNeeded()
                                }
                            } else {
                                FullPlayerArtwork(store: store, item: item, reduceMotion: reduceMotion)
                                    .transition(.opacity)
                            }
                        }
                        .frame(width: side, height: side)
                        .clipped()

                        ArtworkModeControl(store: store)
                            .padding(10)
                    }
                    .animation(.smooth(duration: 0.18), value: store.playerArtworkMode)
                } else {
                    StaticMusicArtwork()
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: PlayerDesign.Radius.small, style: .continuous))
            .clipped()
            .overlay {
                RoundedRectangle(cornerRadius: PlayerDesign.Radius.small, style: .continuous)
                    .strokeBorder(.white.opacity(0.13), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.16), radius: 50, y: 20)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
    }
}

private struct ArtworkModeControl: View {
    @Bindable var store: DownloadStore

    var body: some View {
        HStack(spacing: 2) {
            ArtworkModeButton(
                icon: "photo",
                help: "显示封面",
                isSelected: store.playerArtworkMode == .artwork
            ) {
                store.setPlayerArtworkMode(.artwork)
            }

            ArtworkModeButton(
                icon: "quote.bubble",
                help: "显示歌词",
                isSelected: store.playerArtworkMode == .lyrics
            ) {
                store.setPlayerArtworkMode(.lyrics)
            }
        }
        .padding(4)
        .background(.black.opacity(0.28), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.7)
        }
    }
}

private struct ArtworkModeButton: View {
    let icon: String
    let help: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.62))
                .frame(width: 26, height: 24)
                .background(isSelected ? PlayerDesign.ColorToken.accent.opacity(0.92) : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct LyricsArtworkPanel: View {
    @Bindable var store: DownloadStore
    let item: LibraryMediaItem
    let currentTime: TimeInterval

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: PlayerDesign.Radius.small, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.15, blue: 0.17),
                            Color(red: 0.23, green: 0.24, blue: 0.27)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            switch store.lyricsState {
            case .idle:
                LyricsMessageView(
                    icon: "quote.bubble",
                    title: "准备匹配歌词",
                    message: "\(item.title) · \(item.displayArtist)",
                    primaryTitle: "开始匹配",
                    primaryAction: { store.loadLyricsForSelectedItemIfNeeded(force: true) }
                )
            case .loading:
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                    Text("正在匹配歌词")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PlayerDesign.ColorToken.textPrimary)
                    Text("\(item.title) · \(item.displayArtist)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PlayerDesign.ColorToken.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding(28)
            case .available(let track):
                LyricsContentView(track: track, currentTime: currentTime)
            case .lowConfidence(let track, let reason):
                LyricsMessageView(
                    icon: "exclamationmark.triangle",
                    title: "找到可能匹配",
                    message: "\(reason)\n\(track.trackName) · \(track.artistName)",
                    primaryTitle: "仍然显示",
                    primaryAction: { store.acceptLowConfidenceLyrics() },
                    secondaryTitle: "重新匹配",
                    secondaryAction: { store.reloadLyricsForSelectedItem() }
                )
            case .unavailable(let message):
                LyricsMessageView(
                    icon: "text.badge.xmark",
                    title: "未匹配到歌词",
                    message: message,
                    primaryTitle: "重试",
                    primaryAction: { store.reloadLyricsForSelectedItem() }
                )
            case .failed(let message):
                LyricsMessageView(
                    icon: "wifi.exclamationmark",
                    title: "歌词服务不可用",
                    message: message,
                    primaryTitle: "重试",
                    primaryAction: { store.reloadLyricsForSelectedItem() }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

private struct LyricsContentView: View {
    let track: LyricsTrack
    let currentTime: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("歌词")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(PlayerDesign.ColorToken.textTertiary)
                Text(track.trackName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(PlayerDesign.ColorToken.textPrimary)
                    .lineLimit(1)
                Text("\(track.artistName) · \(track.providerName)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(PlayerDesign.ColorToken.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 10)

            if track.hasSyncedLyrics {
                SyncedLyricsView(track: track, currentTime: currentTime)
            } else if let plainLyrics = track.plainLyrics, !plainLyrics.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                PlainLyricsView(lyrics: plainLyrics)
            } else {
                Text("这条歌词记录没有可显示的内容。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PlayerDesign.ColorToken.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct SyncedLyricsView: View {
    let track: LyricsTrack
    let currentTime: TimeInterval

    private let rowHeight: CGFloat = 62

    private var activeIndex: Int {
        track.activeLineIndex(at: currentTime) ?? 0
    }

    private var focusPosition: CGFloat {
        CGFloat(activeIndex) + transitionProgressToNextLine
    }

    private var transitionProgressToNextLine: CGFloat {
        guard activeIndex + 1 < track.syncedLines.count else { return 0 }
        let currentLineTime = track.syncedLines[activeIndex].time
        let nextLineTime = track.syncedLines[activeIndex + 1].time
        let interval = max(0.1, nextLineTime - currentLineTime)
        let glideDuration = min(max(interval * 0.36, 0.42), 1.15)
        let glideStart = nextLineTime - glideDuration
        guard currentTime > glideStart else { return 0 }
        let rawProgress = (currentTime - glideStart) / glideDuration
        return CGFloat(smoothstep(min(max(rawProgress, 0), 1)))
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(track.syncedLines.enumerated()), id: \.element.id) { index, line in
                    LyricLineRow(
                        text: line.text,
                        distanceFromFocus: abs(CGFloat(index) - focusPosition)
                    )
                    .frame(height: rowHeight, alignment: .leading)
                }
            }
            .padding(.horizontal, 22)
            .offset(y: yOffset(in: proxy.size.height))
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
        .compositingGroup()
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.12),
                    .init(color: .black, location: 0.86),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func yOffset(in height: CGFloat) -> CGFloat {
        let focusCenter = height * 0.50
        let lineCenter = focusPosition * rowHeight + rowHeight * 0.50
        return focusCenter - lineCenter
    }

    private func smoothstep(_ value: Double) -> Double {
        value * value * (3 - 2 * value)
    }
}

private struct LyricLineRow: View {
    let text: String
    let distanceFromFocus: CGFloat

    private var prominence: CGFloat {
        max(0, 1 - distanceFromFocus)
    }

    var body: some View {
        Text(text)
            .font(.system(size: 15 + prominence * 5, weight: prominence > 0.45 ? .bold : .semibold))
            .foregroundStyle(PlayerDesign.ColorToken.textPrimary.opacity(0.34 + prominence * 0.62))
            .lineLimit(2)
            .minimumScaleFactor(0.90)
            .frame(maxWidth: .infinity, alignment: .leading)
            .scaleEffect(1 + prominence * 0.02, anchor: .leading)
    }
}

private struct PlainLyricsView: View {
    let lyrics: String

    var body: some View {
        ScrollView {
            Text(lyrics)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PlayerDesign.ColorToken.textPrimary.opacity(0.86))
                .lineSpacing(7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.vertical, 22)
        }
        .scrollIndicators(.visible)
    }
}

private struct LyricsMessageView: View {
    let icon: String
    let title: String
    let message: String
    let primaryTitle: String?
    let primaryAction: (() -> Void)?
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        primaryTitle: String? = nil,
        primaryAction: (() -> Void)? = nil,
        secondaryTitle: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        VStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(PlayerDesign.ColorToken.textPrimary.opacity(0.86))

            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(PlayerDesign.ColorToken.textPrimary)

            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(PlayerDesign.ColorToken.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)

            HStack(spacing: 10) {
                if let primaryTitle, let primaryAction {
                    Button(primaryTitle, action: primaryAction)
                        .buttonStyle(LyricsPanelButtonStyle(isPrimary: true))
                }

                if let secondaryTitle, let secondaryAction {
                    Button(secondaryTitle, action: secondaryAction)
                        .buttonStyle(LyricsPanelButtonStyle(isPrimary: false))
                }
            }
            .padding(.top, 2)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LyricsPanelButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isPrimary ? .white : PlayerDesign.ColorToken.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(
                isPrimary
                    ? PlayerDesign.ColorToken.accent.opacity(configuration.isPressed ? 0.74 : 0.94)
                    : Color.white.opacity(configuration.isPressed ? 0.18 : 0.12),
                in: Capsule()
            )
    }
}

private struct TrackInfo: View {
    let item: LibraryMediaItem?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text(item?.title ?? "Not Playing")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(PlayerDesign.ColorToken.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(item?.displaySubtitle ?? "--")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PlayerDesign.ColorToken.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxHeight: .infinity, alignment: .top)

            Spacer(minLength: 10)
        }
    }
}

private struct ProgressBar: View {
    let currentTime: Double
    let duration: Double
    let seek: (Double) -> Void

    var body: some View {
        VStack(spacing: 9) {
            Slider(
                value: Binding(
                    get: { min(max(currentTime, 0), effectiveDuration) },
                    set: { seek($0) }
                ),
                in: 0...effectiveDuration
            )
            .tint(PlayerDesign.ColorToken.accent)

            HStack {
                Text(formatTime(currentTime))
                Spacer()
                Text(formatTime(duration))
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(PlayerDesign.ColorToken.textSecondary)
        }
    }

    private var effectiveDuration: Double {
        max(duration.isFinite ? duration : 0, 1)
    }
}

private struct PlaybackControls: View {
    @Bindable var store: DownloadStore
    let item: LibraryMediaItem?
    let metrics: PlayerLayoutMetrics

    var body: some View {
        HStack(spacing: metrics.controlSpacing) {
            Button {
                store.setPlaybackRepeatMode(.all)
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: metrics.smallControlIconSize, weight: .semibold))
            }
            .playerTransportButton(active: store.playbackRepeatMode == .all, diameter: metrics.controlButtonSize)
            .help(PlaybackRepeatMode.all.title)

            Button {
                store.playPreviousLibraryItem()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: metrics.skipControlIconSize, weight: .semibold))
            }
            .playerTransportButton(diameter: metrics.controlButtonSize)
            .disabled(item == nil)
            .help("上一首")

            Button {
                if let item {
                    store.playerController.togglePlayPause(item)
                }
            } label: {
                Image(systemName: store.playerController.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: metrics.playControlIconSize, weight: .semibold))
            }
            .playerTransportButton(prominent: true, diameter: metrics.prominentControlButtonSize)
            .disabled(item == nil)
            .help(store.playerController.isPlaying ? "暂停" : "播放")

            Button {
                store.playNextLibraryItem()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: metrics.skipControlIconSize, weight: .semibold))
            }
            .playerTransportButton(diameter: metrics.controlButtonSize)
            .disabled(item == nil)
            .help("下一首")

            Button {
                store.setPlaybackRepeatMode(.one)
            } label: {
                Image(systemName: "repeat.1")
                    .font(.system(size: metrics.smallControlIconSize, weight: .semibold))
            }
            .playerTransportButton(active: store.playbackRepeatMode == .one, diameter: metrics.controlButtonSize)
            .help(PlaybackRepeatMode.one.title)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 58)
    }
}

private struct QueuePanel: View {
    @Bindable var store: DownloadStore
    let currentItem: LibraryMediaItem?
    let metrics: PlayerLayoutMetrics

    private var queuedItems: [LibraryMediaItem] {
        store.visibleLibraryItems.filter { item in
            item.id != currentItem?.id && item.existsOnDisk
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 18) {
                QueueOptionChip(icon: "infinity", title: "自动播放", isEnabled: store.isAutoPlayEnabled) {
                    store.toggleAutoPlay()
                }
                QueueOptionChip(icon: "shuffle", title: "交叉淡入", isEnabled: store.isCrossfadeEnabled) {
                    store.toggleCrossfade()
                }
            }
            .frame(height: 44)
            .padding(.bottom, metrics.queueHeaderGap)

            HStack(alignment: .firstTextBaseline) {
                Text("接下来播放")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(PlayerDesign.ColorToken.textPrimary)

                Spacer()

                Text("清除")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PlayerDesign.ColorToken.textTertiary.opacity(0.55))
                    .help("暂不支持清空队列")
            }
            .padding(.bottom, 14)

            Rectangle()
                .fill(PlayerDesign.ColorToken.separator)
                .frame(height: 1)
                .padding(.bottom, 20)

            if queuedItems.isEmpty {
                QueueEmptyState()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(queuedItems.prefix(40)) { item in
                            QueueListItem(item: item, isCurrent: false) {
                                store.selectLibraryItem(item)
                            }
                        }
                    }
                    .padding(.trailing, 22)
                    .padding(.bottom, 58)
                }
                .scrollIndicators(.visible)
                .frame(maxHeight: .infinity)
                .clipped()
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .clipped()
    }
}

private struct QueueEmptyState: View {
    var body: some View {
        Text("队列里暂无音乐。")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(PlayerDesign.ColorToken.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct FullPlayerArtwork: View {
    @Bindable var store: DownloadStore
    let item: LibraryMediaItem
    let reduceMotion: Bool

    var body: some View {
        Group {
            if item.mode == .video || item.mode == .videoMP4 {
                VideoPlaybackStageView(item: item, player: store.playerController.avPlayer)
            } else if let artworkURL = item.artworkURL {
                RemoteArtwork(url: artworkURL)
            } else {
                StaticMusicArtwork()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
}

private struct RemoteArtwork: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            case .failure:
                StaticMusicArtwork()
            case .empty:
                StaticMusicArtwork()
                    .overlay {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.secondary)
                    }
            @unknown default:
                StaticMusicArtwork()
            }
        }
    }
}

private extension View {
    func appleMusicTopIconButton() -> some View {
        buttonStyle(AppleMusicTopIconButtonStyle())
            .focusable(false)
    }

    func playerTransportButton(active: Bool = false, prominent: Bool = false, diameter: CGFloat) -> some View {
        modifier(PlayerTransportButtonModifier(active: active, prominent: prominent, diameter: diameter))
    }

}

private struct AppleMusicTopIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(PlayerDesign.ColorToken.textPrimary.opacity(configuration.isPressed ? 0.70 : 0.88))
            .frame(width: 36, height: 30)
            .contentShape(Capsule())
            .background {
                Circle()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.16 : 0.001))
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.smooth(duration: 0.12), value: configuration.isPressed)
    }
}

private struct PlayerTransportButtonModifier: ViewModifier {
    let active: Bool
    let prominent: Bool
    let diameter: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .buttonStyle(PlayerTransportButtonStyle(active: active, prominent: prominent, hovered: isHovered, diameter: diameter))
            .focusable(false)
            .onHover { hovering in
                withAnimation(.smooth(duration: 0.14)) {
                    isHovered = hovering
                }
            }
    }
}

private struct PlayerTransportButtonStyle: ButtonStyle {
    let active: Bool
    let prominent: Bool
    let hovered: Bool
    let diameter: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .foregroundStyle(foreground(isPressed: configuration.isPressed))
            .background {
                Circle()
                    .fill(background(isPressed: configuration.isPressed))
            }
            .scaleEffect(configuration.isPressed ? 0.96 : (hovered ? 1.03 : 1))
            .brightness(configuration.isPressed ? 0.08 : (hovered ? 0.04 : 0))
            .animation(.smooth(duration: 0.12), value: configuration.isPressed)
            .animation(.smooth(duration: 0.14), value: hovered)
            .animation(.smooth(duration: 0.18), value: active)
    }

    private func foreground(isPressed: Bool) -> Color {
        if active {
            return HennessyDesign.ColorToken.accent.opacity(isPressed ? 0.86 : 1)
        }
        return .white.opacity(isPressed ? 0.86 : 0.68)
    }

    private func background(isPressed: Bool) -> Color {
        if active {
            return PlayerDesign.ColorToken.accent.opacity(isPressed ? 0.18 : (hovered ? 0.14 : 0.10))
        }
        return .white.opacity(isPressed ? 0.13 : (hovered ? 0.075 : 0.001))
    }
}

private struct StaticMusicArtwork: View {
    var body: some View {
        RoundedRectangle(cornerRadius: PlayerDesign.Radius.small, style: .continuous)
            .fill(Color.white.opacity(0.86))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.22))
            }
    }
}

private struct QueueOptionChip: View {
    let icon: String
    let title: String
    var isEnabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isEnabled ? PlayerDesign.ColorToken.textPrimary : PlayerDesign.ColorToken.textTertiary.opacity(0.76))
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(PlayerDesign.ColorToken.glassSubtle.opacity(isEnabled ? 1 : 0.62), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(isEnabled ? 0.18 : 0.06), lineWidth: 0.7)
            }
        }
        .buttonStyle(.plain)
        .help(isEnabled ? "\(title)已开启" : "\(title)已关闭")
    }
}

private struct QueueListItem: View {
    let item: LibraryMediaItem
    let isCurrent: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                MediaBadge(item: item, size: 34, highlighted: isCurrent)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(PlayerDesign.ColorToken.textPrimary)
                        .lineLimit(1)
                    Text(item.displaySubtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(PlayerDesign.ColorToken.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()
            }
            .frame(height: 50)
            .padding(.horizontal, 8)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.07) : Color.clear)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.14)) {
                isHovered = hovering
            }
        }
    }
}

private struct LibraryFilterTabs: View {
    @Binding var selection: LibraryFilter
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LibraryFilter.allCases) { filter in
                Button {
                    withAnimation(.smooth(duration: 0.18)) {
                        selection = filter
                    }
                } label: {
                    Label(filter.title, systemImage: filter == .favorites ? "heart" : "music.note.list")
                        .font(.system(size: 13, weight: .semibold))
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(selection == filter ? .white : HennessyDesign.ColorToken.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background {
                            if selection == filter {
                                Capsule()
                                    .fill(HennessyDesign.ColorToken.accent)
                                    .matchedGeometryEffect(id: "library-filter", in: namespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color.white.opacity(0.34), lineWidth: 0.7)
        }
    }
}

private struct MediaBadge: View {
    let item: LibraryMediaItem
    var size: CGFloat = 58
    var highlighted: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: item.mode == .video || item.mode == .videoMP4
                            ? [Color.white.opacity(highlighted ? 0.22 : 0.13), Color.white.opacity(highlighted ? 0.14 : 0.07)]
                            : [PlayerDesign.ColorToken.accent.opacity(highlighted ? 0.98 : 0.84), Color.orange.opacity(highlighted ? 0.82 : 0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: item.mode == .video || item.mode == .videoMP4 ? "play.rectangle" : "waveform")
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 0.8)
        }
    }
}

private struct VideoPlaybackStageView: View {
    let item: LibraryMediaItem
    let player: AVPlayer

    var body: some View {
        ZStack(alignment: .topLeading) {
            AVPlayerContainerView(player: player)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Label(item.existsOnDisk ? item.mediaKindText : "文件不存在", systemImage: item.existsOnDisk ? "film.stack" : "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(item.existsOnDisk ? .white : .red)
                .padding(14)
                .shadow(color: .black.opacity(0.45), radius: 8, y: 3)
        }
        .background(.black.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct AVPlayerContainerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.videoGravity = .resizeAspectFill
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }
}

private struct FullPlayerBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.46, green: 0.47, blue: 0.49),
                Color(red: 0.36, green: 0.37, blue: 0.39),
                Color(red: 0.28, green: 0.29, blue: 0.31)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private func formatTime(_ value: Double) -> String {
    guard value.isFinite, value > 0 else { return "0:00" }
    let total = Int(value.rounded())
    let minutes = total / 60
    let seconds = total % 60
    return "\(minutes):\(String(format: "%02d", seconds))"
}
