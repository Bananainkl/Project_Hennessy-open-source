import SwiftUI

struct SearchPageView: View {
    @Bindable var store: DownloadStore

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                Text("搜索")
                    .font(HennessyDesign.Typography.pageTitle)
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

                SearchFieldBar(
                    text: $store.mediaSearchQuery,
                    isSearching: store.isSearchingMedia,
                    placeholder: "搜索音乐、MV、演出、视频",
                    search: { store.searchMedia() }
                )
            }
            .padding(.horizontal, HennessyDesign.Spacing.contentHorizontal)
            .padding(.top, HennessyDesign.Spacing.contentTop)
            .padding(.bottom, 18)

            if store.isSearchingMedia && store.mediaSearchResults.isEmpty {
                searchingState
            } else if let error = store.mediaSearchError {
                ContentUnavailableView("搜索失败", systemImage: "exclamationmark.triangle", description: Text(error))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.mediaSearchResults.isEmpty {
                ContentUnavailableView("搜索音乐或视频", systemImage: "music.note.list", description: Text("搜索会优先查找 YouTube Music，再补充 YouTube 结果。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                resultList
            }
        }
        .onSubmit {
            store.searchMedia()
        }
        .appleMusicWindowBackground()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("正在搜索...")
                .font(.callout)
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Songs & Videos")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                    Spacer()
                    Text("已显示 \(store.mediaSearchResults.count) 项")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                }
                .padding(.bottom, 10)

                ForEach(store.mediaSearchResults) { result in
                    MediaSearchResultRow(result: result, isDownloadRunning: store.isRunning) {
                        store.useSearchResult(result)
                    } playAudioResult: {
                        store.downloadAndPlaySearchResult(result, mode: .bestAudio)
                    } playVideoResult: {
                        store.downloadAndPlaySearchResult(result, mode: .videoMP4)
                    }
                }

                MediaSearchLoadMoreButton(
                    isSearching: store.isSearchingMedia,
                    canLoadMore: store.canLoadMoreMediaResults,
                    action: { store.loadMoreMediaResults() }
                )
            }
            .padding(.horizontal, HennessyDesign.Spacing.contentHorizontal)
            .padding(.bottom, HennessyDesign.Spacing.miniPlayerReserved)
        }
        .scrollIndicators(.automatic)
    }
}

struct MediaSearchView: View {
    @Bindable var store: DownloadStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if store.isSearchingMedia && store.mediaSearchResults.isEmpty {
                searchingState
            } else if let error = store.mediaSearchError {
                ContentUnavailableView("搜索失败", systemImage: "exclamationmark.triangle", description: Text(error))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.mediaSearchResults.isEmpty {
                ContentUnavailableView("搜索音乐或视频", systemImage: "magnifyingglass", description: Text("输入关键词后，选择一个结果填入下载链接。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                resultList
            }
        }
        .frame(minWidth: 760, minHeight: 560)
        .onSubmit {
            store.searchMedia()
        }
        .appleMusicWindowBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("媒体搜索", systemImage: "magnifyingglass")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Label("关闭", systemImage: "xmark")
                }
                .labelStyle(.iconOnly)
            }

            HStack(spacing: 10) {
                SearchFieldBar(
                    text: $store.mediaSearchQuery,
                    isSearching: store.isSearchingMedia,
                    placeholder: "搜索音乐、MV、演出、视频",
                    search: { store.searchMedia() }
                )
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(20)
    }

    private var searchingState: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("正在搜索...")
                .font(.callout)
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text("Songs & Videos")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                    .padding(.bottom, 8)

                ForEach(store.mediaSearchResults) { result in
                    MediaSearchResultRow(result: result, isDownloadRunning: store.isRunning) {
                        store.useSearchResult(result)
                    } playAudioResult: {
                        store.downloadAndPlaySearchResult(result, mode: .bestAudio)
                    } playVideoResult: {
                        store.downloadAndPlaySearchResult(result, mode: .videoMP4)
                    }
                }

                MediaSearchLoadMoreButton(
                    isSearching: store.isSearchingMedia,
                    canLoadMore: store.canLoadMoreMediaResults,
                    action: { store.loadMoreMediaResults() }
                )
            }
            .padding(20)
        }
    }
}

private struct MediaSearchLoadMoreButton: View {
    let isSearching: Bool
    let canLoadMore: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button {
                action()
            } label: {
                Label(isSearching ? "加载中" : "加载更多结果", systemImage: isSearching ? "clock" : "plus.circle")
            }
            .controlSize(.regular)
            .buttonBorderShape(.capsule)
            .disabled(!canLoadMore)
            .help(canLoadMore ? "继续请求更多搜索结果" : "暂无可继续加载的结果")
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

private struct SearchFieldBar: View {
    @Binding var text: String
    let isSearching: Bool
    let placeholder: String
    let search: () -> Void
    @State private var isHovered = false

    private var canSearch: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSearching
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)

                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .onSubmit(search)

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .imageScale(.small)
                            .foregroundStyle(HennessyDesign.ColorToken.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help("清除")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(isHovered ? 0.58 : 0.38), lineWidth: 0.8)
            }
            .onHover { hovering in
                withAnimation(.smooth(duration: 0.14)) {
                    isHovered = hovering
                }
            }

            Button(action: search) {
                Label(isSearching ? "搜索中" : "搜索", systemImage: isSearching ? "clock" : "magnifyingglass")
            }
            .controlSize(.regular)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(HennessyDesign.ColorToken.accent)
            .disabled(!canSearch)
            .opacity(canSearch ? 1 : 0.42)
            .help(canSearch ? "搜索媒体" : "输入关键词后可搜索")
        }
    }
}

private struct MediaSearchResultRow: View {
    let result: MediaSearchResult
    let isDownloadRunning: Bool
    let useResult: () -> Void
    let playAudioResult: () -> Void
    let playVideoResult: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 5) {
                Text(result.title)
                    .font(HennessyDesign.Typography.rowTitle)
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(result.channel)
                    Text(result.durationText)
                }
                .font(.caption)
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary)

                Text(result.url)
                .font(.caption2)
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary.opacity(0.72))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    playAudioResult()
                } label: {
                    Label("音乐", systemImage: "music.note")
                }
                .controlSize(.small)
                .buttonBorderShape(.capsule)
                .disabled(isDownloadRunning)

                Button {
                    playVideoResult()
                } label: {
                    Label("视频", systemImage: "film")
                }
                .controlSize(.small)
                .buttonBorderShape(.capsule)
                .disabled(isDownloadRunning)

                Button {
                    useResult()
                } label: {
                    Label("链接", systemImage: "link.badge.plus")
                }
                .controlSize(.small)
                .buttonBorderShape(.capsule)
            }
        }
        .frame(minHeight: 72)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHovered ? HennessyDesign.ColorToken.hover : Color.clear)
        }
        .overlay {
            Rectangle()
                .fill(HennessyDesign.ColorToken.separator.opacity(0.70))
                .frame(height: 0.7)
                .padding(.leading, 126)
                .frame(maxHeight: .infinity, alignment: .bottom)
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
                case .failure:
                    placeholder
                case .empty:
                    ProgressView()
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 112, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.quaternary)
            .frame(width: 112, height: 64)
            .overlay {
                Image(systemName: "play.rectangle")
                    .foregroundStyle(.secondary)
            }
    }
}
