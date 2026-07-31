import SwiftUI

struct DownloadFormView: View {
    @Bindable var store: DownloadStore
    @State private var inputMode: DownloadInputMode = .single

    var body: some View {
        ScrollView {
            glassContent
        }
        .scrollContentBackground(.hidden)
        .appleMusicWindowBackground()
    }

    @ViewBuilder
    private var glassContent: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer {
                contentStack
            }
        } else {
            contentStack
        }
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 14) {
            statusHeader
            inputModePicker
            if inputMode == .single {
                urlPanel
            } else if inputMode == .playlist {
                playlistPanel
            } else {
                creatorPanel
            }
            modePanel
            if inputMode == .single {
                metadataPanel
            }
            ActivityLogView(logText: store.logText, isRunning: store.isRunning)
                .transaction { transaction in
                    transaction.animation = nil
                }
        }
        .padding(.horizontal, HennessyDesign.Spacing.contentHorizontal)
        .padding(.top, HennessyDesign.Spacing.contentTop)
        .padding(.bottom, HennessyDesign.Spacing.miniPlayerReserved + 12)
        .frame(maxWidth: 980, alignment: .topLeading)
    }

    private var statusHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: store.isRunning
                            ? [HennessyDesign.ColorToken.accent, Color.orange.opacity(0.76)]
                            : [HennessyDesign.ColorToken.glassStrong, HennessyDesign.ColorToken.glassSubtle],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: store.isRunning ? "arrow.down.circle.fill" : "sparkles")
                        .font(.system(size: 19, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(store.isRunning ? .white.opacity(0.92) : HennessyDesign.ColorToken.textSecondary)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text("媒体下载")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

                HStack(spacing: 8) {
                    Text(store.statusMessage)
                    if !store.progressDetail.isEmpty {
                        Text(store.progressDetail)
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary)

                progressRow

                if let errorSummary = store.errorSummary {
                    Text(errorSummary)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                if store.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    startCurrentDownload()
                } label: {
                    Label(downloadButtonTitle, systemImage: downloadButtonIcon)
                }
                .lineLimit(1)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!canStartCurrentDownload)
                .downloadActionButtonStyle(isActive: canStartCurrentDownload)
                .help(downloadButtonHelp)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 10)
        .frame(minHeight: 76)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HennessyDesign.ColorToken.separator)
                .frame(height: 0.7)
        }
    }

    private var downloadButtonTitle: String {
        if store.isRunning {
            return "下载中"
        }
        switch inputMode {
        case .single:
            return store.canStartDownload ? "开始下载" : "等待链接"
        case .playlist:
            let count = store.playlistPreviewEntries.count
            return count > 0 ? "下载 \(count) 首" : "等待歌单"
        case .creator:
            let count = store.selectedCreatorResults.count
            return count > 0 ? "下载 \(count) 项" : "等待选择"
        }
    }

    private var downloadButtonIcon: String {
        if store.isRunning {
            return "clock"
        }
        switch inputMode {
        case .single:
            return "arrow.down.circle"
        case .playlist:
            return "arrow.down.doc"
        case .creator:
            return "person.crop.square.badge.arrow.down"
        }
    }

    private var downloadButtonHelp: String {
        switch inputMode {
        case .single:
            return store.canStartDownload ? "开始下载" : "粘贴有效链接后可开始下载"
        case .playlist:
            return store.canStartPlaylistDownload ? "逐首搜索并下载歌单" : "粘贴一行一首的歌单"
        case .creator:
            return store.canStartCreatorDownload ? "下载所选创作者发布内容" : "先搜索创作者并勾选要下载的内容"
        }
    }

    private var canStartCurrentDownload: Bool {
        switch inputMode {
        case .single:
            return store.canStartDownload
        case .playlist:
            return store.canStartPlaylistDownload
        case .creator:
            return store.canStartCreatorDownload
        }
    }

    private func startCurrentDownload() {
        switch inputMode {
        case .single:
            store.startDownload()
        case .playlist:
            store.startPlaylistDownload()
        case .creator:
            store.startCreatorSelectionDownload()
        }
    }

    private var inputModePicker: some View {
        Picker("下载方式", selection: $inputMode) {
            ForEach(DownloadInputMode.allCases) { mode in
                Label(mode.title, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(maxWidth: 520)
        .accessibilityIdentifier("download-input-mode-picker")
    }

    @ViewBuilder
    private var progressRow: some View {
        if store.isRunning || store.downloadProgress != nil {
            HStack(spacing: 10) {
                if let progress = store.downloadProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(width: 180)
                    Text(store.progressDetail)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                } else {
                    ProgressView()
                        .controlSize(.small)
                    Text(store.progressDetail.isEmpty ? "准备中" : store.progressDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
    }

    private var urlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("链接", systemImage: "link")
                .font(HennessyDesign.Typography.cardTitle)
                .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

            DownloadGlassTextField(
                placeholder: "粘贴 YouTube、Bilibili 或其他 yt-dlp 支持的网页链接",
                text: $store.urlText,
                systemImage: "link"
            )

            HStack(spacing: 10) {
                Text(store.outputDirectory.path)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button {
                    store.chooseOutputDirectory()
                } label: {
                    Label("保存目录", systemImage: "folder")
                }
                .controlSize(.regular)
                .buttonBorderShape(.capsule)
            }

            Toggle("允许下载播放列表", isOn: $store.allowPlaylist)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(16)
        .appleMusicCard()
    }

    private var modePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("格式", systemImage: "slider.horizontal.3")
                .font(HennessyDesign.Typography.cardTitle)
                .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
                ForEach(DownloadMode.allCases) { mode in
                    ModeCard(mode: mode, isSelected: store.selectedMode == mode) {
                        store.selectedMode = mode
                    }
                }
            }
        }
        .padding(16)
        .appleMusicCard()
    }

    private var playlistPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("批量歌单", systemImage: "text.badge.plus")
                    .font(HennessyDesign.Typography.cardTitle)
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

                Spacer()

                Text(store.playlistPreviewEntries.isEmpty ? "一行一首" : "已识别 \(store.playlistPreviewEntries.count) 首")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
            }

            DownloadGlassTextEditor(
                placeholder: "粘贴歌单，例如：\n梁静茹 - 小手拉大手\n林俊傑 - 江南\nhttps://www.youtube.com/watch?v=...",
                text: $store.playlistText
            )

            PlaylistPreviewView(
                entries: store.playlistPreviewEntries,
                progressItems: store.playlistProgressItems
            )

            HStack(spacing: 10) {
                Text("文字会自动搜索；链接会直接下载。建议使用「歌手 - 歌名」格式。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                    .lineLimit(2)

                Spacer()

                Button {
                    store.startPlaylistDownload()
                } label: {
                    Label(store.playlistPreviewEntries.isEmpty ? "下载歌单" : "下载 \(store.playlistPreviewEntries.count) 首", systemImage: "arrow.down.doc")
                }
                .controlSize(.regular)
                .buttonBorderShape(.capsule)
                .disabled(!store.canStartPlaylistDownload)
                .help(store.canStartPlaylistDownload ? "逐首搜索并下载歌单" : "粘贴一行一首的歌单")
            }
        }
        .padding(16)
        .appleMusicCard()
    }

    private var creatorPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("创作者发布", systemImage: "person.crop.square")
                    .font(HennessyDesign.Typography.cardTitle)
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

                Spacer()

                if let channel = store.creatorSearchChannel {
                    Text(channel.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("按频道读取发布列表")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                }
            }

            HStack(spacing: 10) {
                DownloadGlassTextField(
                    placeholder: "输入创作者名称，例如 G.E.M. 邓紫棋",
                    text: $store.creatorSearchQuery,
                    systemImage: "person.text.rectangle"
                )
                .onSubmit {
                    store.searchCreatorMedia()
                }

                Button {
                    store.searchCreatorMedia()
                } label: {
                    Label(store.isSearchingCreator ? "搜索中" : "搜索", systemImage: store.isSearchingCreator ? "clock" : "magnifyingglass")
                }
                .controlSize(.regular)
                .buttonBorderShape(.capsule)
                .disabled(!store.canSearchCreator)
                .help(store.canSearchCreator ? "搜索创作者发布列表" : "输入创作者名称后可搜索")
            }

            creatorSearchBody
        }
        .padding(16)
        .appleMusicCard()
    }

    @ViewBuilder
    private var creatorSearchBody: some View {
        if store.isSearchingCreator && store.creatorSearchResults.isEmpty {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("正在匹配频道并读取发布列表")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        } else if let error = store.creatorSearchError {
            Label(error, systemImage: "exclamationmark.triangle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.red)
                .padding(.vertical, 8)
        } else if store.creatorSearchResults.isEmpty {
            Label("搜索后会显示该创作者发布的视频和音乐内容，可勾选后下载。", systemImage: "checklist")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                creatorSelectionHeader
                CreatorResultSelectionList(
                    results: store.creatorSearchResults,
                    selectedIDs: store.selectedCreatorResultIDs,
                    isDownloadRunning: store.isRunning,
                    toggle: { store.toggleCreatorResultSelection($0) }
                )

                HStack(spacing: 10) {
                    Text("已选择 \(store.selectedCreatorResults.count) / 已显示 \(store.creatorSearchResults.count) 项")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)

                    Spacer()

                    Button {
                        store.loadMoreCreatorResults()
                    } label: {
                        Label(store.isSearchingCreator ? "加载中" : "加载更多", systemImage: store.isSearchingCreator ? "clock" : "plus.circle")
                    }
                    .controlSize(.regular)
                    .buttonBorderShape(.capsule)
                    .disabled(!store.canLoadMoreCreatorResults)
                    .help(store.canLoadMoreCreatorResults ? "继续加载这个创作者更早发布的内容" : "暂无可继续加载的结果")

                    Button {
                        store.startCreatorSelectionDownload()
                    } label: {
                        Label("下载所选", systemImage: "arrow.down.circle")
                    }
                    .controlSize(.regular)
                    .buttonBorderShape(.capsule)
                    .disabled(!store.canStartCreatorDownload)
                }
            }
        }
    }

    private var creatorSelectionHeader: some View {
        HStack(spacing: 10) {
            if let channel = store.creatorSearchChannel {
                CreatorChannelBadge(channel: channel)
            }

            Spacer()

            Button("全选") {
                store.selectAllCreatorResults()
            }
            .controlSize(.small)
            .disabled(store.creatorSearchResults.isEmpty || store.isRunning)

            Button("清空") {
                store.clearCreatorSelection()
            }
            .controlSize(.small)
            .disabled(store.selectedCreatorResults.isEmpty || store.isRunning)
        }
    }

    private var metadataPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("可选命名", systemImage: "tag")
                .font(HennessyDesign.Typography.cardTitle)
                .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    Text("标题")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                    DownloadGlassTextField(placeholder: "自动识别", text: $store.titleOverride, systemImage: "textformat")
                }

                GridRow {
                    Text("作者")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                    DownloadGlassTextField(placeholder: "自动识别", text: $store.artistOverride, systemImage: "person")
                }
            }
        }
        .padding(16)
        .appleMusicCard()
    }
}

private struct DownloadGlassTextField: View {
    let placeholder: String
    @Binding var text: String
    let systemImage: String
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                        Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HennessyDesign.ColorToken.textTertiary)
                }
                .buttonStyle(.plain)
                .help("清除")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(HennessyDesign.ColorToken.glassSubtle, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(isHovered ? HennessyDesign.ColorToken.accent.opacity(0.46) : HennessyDesign.ColorToken.separator.opacity(0.92), lineWidth: 0.8)
        }
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.14)) {
                isHovered = hovering
            }
        }
    }
}

private struct DownloadGlassTextEditor: View {
    let placeholder: String
    @Binding var text: String
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)

            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HennessyDesign.ColorToken.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: 112)
        .background(HennessyDesign.ColorToken.glassSubtle, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(isHovered ? HennessyDesign.ColorToken.accent.opacity(0.46) : HennessyDesign.ColorToken.separator.opacity(0.92), lineWidth: 0.8)
        }
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.14)) {
                isHovered = hovering
            }
        }
    }
}

private enum DownloadInputMode: String, CaseIterable, Identifiable {
    case single
    case playlist
    case creator

    var id: String { rawValue }

    var title: String {
        switch self {
        case .single: "单首链接"
        case .playlist: "批量歌单"
        case .creator: "创作者"
        }
    }

    var icon: String {
        switch self {
        case .single: "link"
        case .playlist: "text.badge.plus"
        case .creator: "person.crop.square"
        }
    }
}

private struct CreatorChannelBadge: View {
    let channel: CreatorSearchCandidate

    var body: some View {
        HStack(spacing: 8) {
            channelImage

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                    .lineLimit(1)

                if !channel.subtitle.isEmpty {
                    Text(channel.subtitle)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: 280, alignment: .leading)
    }

    @ViewBuilder
    private var channelImage: some View {
        if let thumbnailURL = channel.thumbnailURL {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty, .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(HennessyDesign.ColorToken.glassSubtle)
            .frame(width: 34, height: 34)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
            }
    }
}

private struct CreatorResultSelectionList: View {
    let results: [MediaSearchResult]
    let selectedIDs: Set<String>
    let isDownloadRunning: Bool
    let toggle: (MediaSearchResult) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(results) { result in
                    CreatorResultSelectionRow(
                        result: result,
                        isSelected: selectedIDs.contains(result.id),
                        isDownloadRunning: isDownloadRunning,
                        toggle: { toggle(result) }
                    )
                }
            }
        }
        .frame(maxHeight: 360)
        .background(HennessyDesign.ColorToken.glassSubtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(HennessyDesign.ColorToken.separator.opacity(0.86), lineWidth: 0.7)
        }
    }
}

private struct CreatorResultSelectionRow: View {
    let result: MediaSearchResult
    let isSelected: Bool
    let isDownloadRunning: Bool
    let toggle: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? HennessyDesign.ColorToken.accent : HennessyDesign.ColorToken.textSecondary)
                    .frame(width: 22)

                thumbnail

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(result.channel)
                        Text(result.durationText)
                    }
                    .font(.caption)
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
            .background(isHovered ? HennessyDesign.ColorToken.hover : Color.clear)
        }
        .buttonStyle(.plain)
        .disabled(isDownloadRunning)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HennessyDesign.ColorToken.separator.opacity(0.72))
                .frame(height: 0.7)
                .padding(.leading, 112)
        }
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.14)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let thumbnailURL = result.thumbnailURL {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty, .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 72, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(.quaternary)
            .frame(width: 72, height: 42)
            .overlay {
                Image(systemName: "play.rectangle")
                    .foregroundStyle(.secondary)
            }
    }
}

private struct PlaylistPreviewView: View {
    let entries: [PlaylistDownloadEntry]
    let progressItems: [PlaylistDownloadProgressItem]

    private var rows: [PlaylistPreviewRow] {
        if !progressItems.isEmpty {
            return progressItems.map { item in
                PlaylistPreviewRow(
                    index: item.id,
                    entry: item.entry,
                    state: item.state,
                    detail: item.detail
                )
            }
        }

        return entries.enumerated().map { index, entry in
            PlaylistPreviewRow(
                index: index,
                entry: entry,
                state: nil,
                detail: entry.url == nil ? "将搜索：\(entry.searchQuery)" : "将直接下载链接"
            )
        }
    }

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("解析预览", systemImage: "list.bullet.rectangle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

                    Spacer()

                    Text("\(rows.count) 首")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                }

                VStack(spacing: 0) {
                    ForEach(rows.prefix(6)) { row in
                        PlaylistPreviewRowView(row: row)
                    }

                    if rows.count > 6 {
                        Text("还有 \(rows.count - 6) 首将在下载时继续处理")
                            .font(.caption)
                            .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                    }
                }
                .background(HennessyDesign.ColorToken.glassSubtle, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(HennessyDesign.ColorToken.separator.opacity(0.86), lineWidth: 0.7)
                }
            }
        }
    }
}

private struct PlaylistPreviewRow: Identifiable {
    let index: Int
    let entry: PlaylistDownloadEntry
    let state: PlaylistDownloadProgressState?
    let detail: String

    var id: Int { index }
}

private struct PlaylistPreviewRowView: View {
    let row: PlaylistPreviewRow

    var body: some View {
        HStack(spacing: 10) {
            Text("\(row.index + 1)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                .frame(width: 22, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.entry.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                    .lineLimit(1)

                Text(row.detail)
                    .font(.caption)
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            if let state = row.state {
                Text(state.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(stateColor(state))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(stateColor(state).opacity(0.13), in: Capsule())
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(HennessyDesign.ColorToken.separator.opacity(0.72))
                .frame(height: 0.7)
                .padding(.leading, 42)
        }
    }

    private func stateColor(_ state: PlaylistDownloadProgressState) -> Color {
        switch state {
        case .done, .duplicate:
            return .green
        case .failed:
            return .red
        case .matched, .downloading:
            return HennessyDesign.ColorToken.accent
        case .searching:
            return .orange
        case .pending:
            return HennessyDesign.ColorToken.textSecondary
        }
    }
}

private struct ModeCard: View {
    let mode: DownloadMode
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                    Text(mode.subtitle)
                        .font(.caption)
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(11)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? HennessyDesign.ColorToken.accentSoft : (isHovered ? HennessyDesign.ColorToken.hover : HennessyDesign.ColorToken.glassSubtle))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(isSelected ? HennessyDesign.ColorToken.accent.opacity(0.72) : HennessyDesign.ColorToken.separator, lineWidth: isSelected ? 1.2 : 0.7)
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
