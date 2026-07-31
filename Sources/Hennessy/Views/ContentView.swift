import SwiftUI

struct ContentView: View {
    @Bindable var store: DownloadStore
    @AppStorage("windowAppearanceStyle") private var windowAppearanceStyle = WindowAppearanceStyle.glass

    var body: some View {
        ZStack {
            Color.clear
                .liquidGlassBackdrop(style: windowAppearanceStyle)
                .background(WindowGlassConfigurator().frame(width: 0, height: 0))
            .ignoresSafeArea()

            NavigationSplitView {
                SidebarView(selection: $store.selectedSection)
                    .navigationSplitViewColumnWidth(
                        min: HennessyDesign.Component.sidebarMinWidth,
                        ideal: HennessyDesign.Component.sidebarIdealWidth,
                        max: HennessyDesign.Component.sidebarMaxWidth
                    )
            } detail: {
                ZStack(alignment: .bottom) {
                    Group {
                        switch store.selectedSection {
                        case .search:
                            SearchPageView(store: store)
                        case .download:
                            DownloadFormView(store: store)
                        case .player:
                            PlayerView(store: store)
                        case .recent:
                            RecentPlayedView(store: store)
                        case .history:
                            HistoryView(store: store)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if !store.isFullPlayerPresented {
                        PersistentMiniPlayerBar(store: store)
                            .padding(.horizontal, HennessyDesign.Spacing.miniPlayerHorizontal)
                            .padding(.bottom, HennessyDesign.Spacing.miniPlayerBottom)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .appleMusicWindowBackground()
                .navigationTitle(store.isFullPlayerPresented ? "" : store.selectedSection.title)
                .toolbarBackground(.hidden, for: .windowToolbar)
                .toolbar(store.isFullPlayerPresented ? .hidden : .visible, for: .windowToolbar)
                .toolbar {
                    ToolbarItemGroup {
                        Button {
                            store.selectedSection = .search
                        } label: {
                            Label("搜索媒体", systemImage: "magnifyingglass")
                        }
                        .help("搜索音乐或视频")
                        .accessibilityIdentifier("toolbar-search")

                        Button {
                            store.chooseOutputDirectory()
                        } label: {
                            Label("选择保存目录", systemImage: "folder")
                        }
                        .help("选择保存目录")
                        .accessibilityIdentifier("toolbar-output-directory")

                        Button {
                            store.revealLastOutput()
                        } label: {
                            Label("在访达中显示", systemImage: "arrow.up.forward.app")
                        }
                        .disabled(store.lastOutputURL == nil)
                        .help(store.lastOutputURL == nil ? "暂无可显示的下载文件" : "在访达中显示最近下载")
                        .accessibilityIdentifier("toolbar-reveal-last-output")
                    }

                    ToolbarItemGroup {
                        Button {
                            store.cancelDownload()
                        } label: {
                            Label("停止", systemImage: "stop.fill")
                        }
                        .disabled(!store.isRunning)
                        .help(store.isRunning ? "停止当前下载" : "当前没有下载任务")
                        .accessibilityIdentifier("toolbar-stop-download")

                        Button {
                            store.startDownload()
                        } label: {
                            Label(store.isRunning ? "下载中" : "开始", systemImage: "arrow.down.circle")
                        }
                        .keyboardShortcut(.return, modifiers: .command)
                        .disabled(!store.canStartDownload)
                        .toolbarDownloadButtonStyle(isActive: store.canStartDownload || store.isRunning)
                        .help(store.canStartDownload ? "开始下载" : "请输入有效链接")
                        .accessibilityIdentifier("toolbar-start-download")
                    }
                }
            }
            .toolbarBackground(.hidden, for: .windowToolbar)
            .toolbar(store.isFullPlayerPresented ? .hidden : .visible, for: .windowToolbar)
            .clearWindowContainerBackground()
            .background(Color.clear)
            .opacity(store.isFullPlayerPresented ? 0 : 1)
            .allowsHitTesting(!store.isFullPlayerPresented)

            if store.isFullPlayerPresented {
                FullPlayerView(store: store, reduceMotion: false)
                    .ignoresSafeArea()
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
            }
        }
        .animation(.smooth(duration: 0.34), value: store.isFullPlayerPresented)
        .sheet(isPresented: $store.isSearchPresented) {
            MediaSearchView(store: store)
        }
        .sheet(item: $store.editingLibraryItem) { item in
            LibraryMetadataEditorView(item: item) { title, artist in
                store.updateLibraryItemMetadata(item, title: title, artist: artist)
            }
        }
        .tint(HennessyDesign.ColorToken.accent)
        .environment(\.windowAppearanceStyle, windowAppearanceStyle)
        .preferredColorScheme(windowAppearanceStyle == .desktopTransparency ? .dark : nil)
        .task {
            store.startAudioQualityAuditIfNeeded()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

private extension View {
    @ViewBuilder
    func clearWindowContainerBackground() -> some View {
        if #available(macOS 15.0, *) {
            containerBackground(.clear, for: .window)
        } else {
            self
        }
    }
}

private struct PersistentMiniPlayerBar: View {
    @Bindable var store: DownloadStore

    var body: some View {
        HStack(spacing: 16) {
            transportControls
                .frame(
                    minWidth: HennessyDesign.Component.miniTransportMinWidth,
                    idealWidth: HennessyDesign.Component.miniTransportIdealWidth,
                    maxWidth: HennessyDesign.Component.miniTransportMaxWidth,
                    alignment: .leading
                )
                .layoutPriority(2)

            Button {
                guard store.selectedLibraryItem != nil else { return }
                withAnimation(.smooth(duration: 0.34)) {
                    store.isFullPlayerPresented = true
                }
            } label: {
                centerSummary
            }
            .buttonStyle(.plain)
            .miniPlayerSummaryFeedback(isEnabled: store.selectedLibraryItem != nil)
            .focusable(false)
            .frame(
                minWidth: HennessyDesign.Component.miniSummaryMinWidth,
                idealWidth: HennessyDesign.Component.miniSummaryIdealWidth,
                maxWidth: HennessyDesign.Component.miniSummaryMaxWidth
            )
            .padding(.leading, 18)
            .layoutPriority(3)
            .disabled(store.selectedLibraryItem == nil)
            .help(store.selectedLibraryItem == nil ? "暂无播放内容" : "打开播放器")

            trailingControls
                .frame(
                    minWidth: HennessyDesign.Component.miniTrailingMinWidth,
                    idealWidth: HennessyDesign.Component.miniTrailingIdealWidth,
                    maxWidth: HennessyDesign.Component.miniTrailingMaxWidth,
                    alignment: .trailing
                )
                .layoutPriority(4)
        }
        .frame(height: HennessyDesign.Spacing.miniPlayerHeight)
        .padding(.horizontal, 16)
        .glassPanel(cornerRadius: HennessyDesign.Radius.player)
    }

    private var transportControls: some View {
        HStack(spacing: 13) {
            Button {
                store.setPlaybackRepeatMode(.all)
            } label: {
                Image(systemName: "shuffle")
            }
            .miniPlayerControlButton(active: store.playbackRepeatMode == .all)
            .help(PlaybackRepeatMode.all.title)

            Button {
                store.playPreviousLibraryItem()
            } label: {
                Image(systemName: "backward.fill")
            }
            .miniPlayerControlButton()
            .help("上一首")
            .disabled(store.selectedLibraryItem == nil)

            Button {
                if let item = store.selectedLibraryItem {
                    store.playerController.togglePlayPause(item)
                }
            } label: {
                Image(systemName: store.playerController.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 21, weight: .semibold))
            }
            .miniPlayerControlButton(prominent: true)
            .help(store.playerController.isPlaying ? "暂停" : "播放")
            .disabled(store.selectedLibraryItem == nil)

            Button {
                store.playNextLibraryItem()
            } label: {
                Image(systemName: "forward.fill")
            }
            .miniPlayerControlButton()
            .help("下一首")
            .disabled(store.selectedLibraryItem == nil)

            Button {
                store.setPlaybackRepeatMode(.one)
            } label: {
                Image(systemName: "repeat.1")
            }
            .miniPlayerControlButton(active: store.playbackRepeatMode == .one)
            .help(PlaybackRepeatMode.one.title)
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(store.selectedLibraryItem == nil ? Color.secondary.opacity(0.55) : Color.primary.opacity(0.76))
    }

    private var centerSummary: some View {
        HStack(spacing: 12) {
            if let item = store.selectedLibraryItem {
                MiniArtwork(item: item)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.88)
                    Text(item.displayArtist)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            } else {
                Image(systemName: "music.note")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Not Playing")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var trailingControls: some View {
        HStack(spacing: 18) {
            Button {
                if store.selectedLibraryItem != nil {
                    withAnimation(.smooth(duration: 0.34)) {
                        store.isFullPlayerPresented = true
                        store.setPlayerArtworkMode(.lyrics)
                    }
                }
            } label: {
                Image(systemName: "quote.bubble")
            }
            .miniPlayerControlButton()
            .disabled(store.selectedLibraryItem == nil)
            .help("显示歌词")

            Button {
                if store.selectedLibraryItem != nil {
                    withAnimation(.smooth(duration: 0.34)) {
                        store.isFullPlayerPresented = true
                    }
                }
            } label: {
                Image(systemName: "list.bullet")
            }
            .miniPlayerControlButton()
            .help("播放队列")
            .disabled(store.selectedLibraryItem == nil)

            HStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { store.playerController.volume },
                        set: { store.playerController.setVolume($0) }
                    ),
                    in: 0...1
                )
                .tint(HennessyDesign.ColorToken.accent)
                .frame(width: HennessyDesign.Component.miniVolumeWidth)
                .layoutPriority(-1)

                Image(systemName: "speaker.wave.3.fill")
            }
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.primary.opacity(0.80))
    }
}

private struct MiniArtwork: View {
    let item: LibraryMediaItem

    var body: some View {
        Group {
            if let artworkURL = item.artworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        placeholder
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: HennessyDesign.Component.miniArtwork, height: HennessyDesign.Component.miniArtwork)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.7)
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(
                item.mode == .video || item.mode == .videoMP4
                    ? LinearGradient(colors: [Color.gray.opacity(0.75), Color.black.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [HennessyDesign.ColorToken.accent.opacity(0.88), Color.orange.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay {
                Image(systemName: item.mode.icon)
                    .foregroundStyle(.white.opacity(0.78))
            }
    }
}

private extension View {
    func miniPlayerControlButton(active: Bool = false, prominent: Bool = false) -> some View {
        modifier(MiniPlayerControlButtonModifier(active: active, prominent: prominent))
    }

    func miniPlayerSummaryFeedback(isEnabled: Bool) -> some View {
        modifier(MiniPlayerSummaryFeedbackModifier(isEnabled: isEnabled))
    }
}

private struct MiniPlayerSummaryFeedbackModifier: ViewModifier {
    let isEnabled: Bool
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isHovered && isEnabled ? HennessyDesign.ColorToken.hover : Color.clear)
            }
            .scaleEffect(isHovered && isEnabled ? 1.012 : 1)
            .animation(.smooth(duration: 0.14), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

private struct MiniPlayerControlButtonModifier: ViewModifier {
    let active: Bool
    let prominent: Bool
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .buttonStyle(MiniPlayerControlButtonStyle(active: active, prominent: prominent, hovered: isHovered))
            .focusable(false)
            .onHover { hovering in
                withAnimation(.smooth(duration: 0.14)) {
                    isHovered = hovering
                }
            }
    }
}

private struct MiniPlayerControlButtonStyle: ButtonStyle {
    let active: Bool
    let prominent: Bool
    let hovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: prominent ? 36 : 30, height: prominent ? 36 : 30)
            .contentShape(Circle())
            .foregroundStyle(foreground(isPressed: configuration.isPressed))
            .background {
                Circle()
                    .fill(background(isPressed: configuration.isPressed))
            }
            .overlay {
                Circle()
                    .strokeBorder(.primary.opacity(borderOpacity(isPressed: configuration.isPressed)), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.90 : (hovered ? 1.06 : 1))
            .brightness(configuration.isPressed ? 0.08 : (hovered ? 0.04 : 0))
            .animation(.smooth(duration: 0.12), value: configuration.isPressed)
            .animation(.smooth(duration: 0.14), value: hovered)
            .animation(.smooth(duration: 0.18), value: active)
    }

    private func foreground(isPressed: Bool) -> Color {
        if active {
            return HennessyDesign.ColorToken.accent.opacity(isPressed ? 0.82 : 1)
        }
        return Color.primary.opacity(isPressed ? 0.72 : 0.78)
    }

    private func background(isPressed: Bool) -> Color {
        if active {
            return HennessyDesign.ColorToken.accent.opacity(isPressed ? 0.18 : (hovered ? 0.14 : 0.09))
        }
        return Color.primary.opacity(isPressed ? 0.13 : (hovered ? 0.075 : 0.001))
    }

    private func borderOpacity(isPressed: Bool) -> Double {
        if active {
            return isPressed ? 0.20 : (hovered ? 0.16 : 0.08)
        }
        return isPressed ? 0.14 : (hovered ? 0.10 : 0)
    }
}
