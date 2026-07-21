import SwiftUI

struct MediaListView: View {
    let items: [LibraryMediaItem]
    let selectedID: String?
    let qualityForItem: (LibraryMediaItem) -> AudioQualityInfo?
    let select: (LibraryMediaItem) -> Void
    let toggleFavorite: (LibraryMediaItem) -> Void
    let refreshArtwork: (LibraryMediaItem) -> Void
    let edit: (LibraryMediaItem) -> Void
    let reveal: (LibraryMediaItem) -> Void
    let remove: (LibraryMediaItem) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    MediaListItemView(
                        item: item,
                        quality: qualityForItem(item),
                        isSelected: selectedID == item.id,
                        isLast: index == items.count - 1,
                        select: { select(item) },
                        toggleFavorite: { toggleFavorite(item) },
                        edit: { edit(item) }
                    )
                    .contextMenu {
                        Button("播放") { select(item) }
                        Button(item.isFavorite ? "取消收藏" : "收藏") { toggleFavorite(item) }
                        Button("编辑信息") { edit(item) }
                        Button("刷新专辑封面") { refreshArtwork(item) }
                            .disabled(!item.isAudio)
                        Button("在访达中显示") { reveal(item) }
                        Divider()
                        Button("从播放列表移除", role: .destructive) { remove(item) }
                    }
                }
            }
            .padding(.bottom, HennessyDesign.Spacing.miniPlayerReserved)
        }
        .scrollIndicators(.automatic)
    }
}

private struct MediaListItemView: View {
    let item: LibraryMediaItem
    let quality: AudioQualityInfo?
    let isSelected: Bool
    let isLast: Bool
    let select: () -> Void
    let toggleFavorite: () -> Void
    let edit: () -> Void
    @State private var isHovered = false
    @State private var favoriteHovered = false
    @State private var editHovered = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .leading) {
                MediaListArtwork(item: item)
                if isSelected {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(HennessyDesign.ColorToken.accent)
                        .frame(width: 3, height: 30)
                        .offset(x: -8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(HennessyDesign.Typography.rowTitle)
                    .foregroundStyle(isSelected ? HennessyDesign.ColorToken.accent : HennessyDesign.ColorToken.textPrimary)
                    .lineLimit(1)
                Text(item.displaySubtitle)
                    .font(HennessyDesign.Typography.rowSubtitle)
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 18)

            if let quality, item.isAudio {
                Text(quality.qualityDescription)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(qualityBadgeColor(quality))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(qualityBadgeColor(quality).opacity(0.12), in: Capsule())
                    .help(quality.compactDescription)
            }

            Button(action: edit) {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary.opacity(editHovered || isHovered ? 0.92 : 0.54))
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .opacity(isHovered || editHovered ? 1 : 0)
            .help("编辑歌曲名和歌手")
            .onHover { hovering in
                withAnimation(.smooth(duration: 0.14)) {
                    editHovered = hovering
                }
            }

            Button(action: toggleFavorite) {
                Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(item.isFavorite ? HennessyDesign.ColorToken.accent : HennessyDesign.ColorToken.textSecondary.opacity(favoriteHovered || isHovered ? 0.92 : 0.54))
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.smooth(duration: 0.14)) {
                    favoriteHovered = hovering
                }
            }
        }
        .frame(height: HennessyDesign.Component.mediaRowHeight)
        .padding(.horizontal, 16)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? HennessyDesign.ColorToken.selected : (isHovered ? HennessyDesign.ColorToken.hover : Color.clear))
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(HennessyDesign.ColorToken.separator.opacity(isSelected || isHovered ? 0 : 0.74))
                    .frame(height: 0.7)
                    .padding(.leading, 68)
            }
        }
        .onTapGesture(perform: select)
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.14)) {
                isHovered = hovering
            }
        }
    }

    private func qualityBadgeColor(_ quality: AudioQualityInfo) -> Color {
        if quality.isLikelyTranscoded { return .orange }
        switch quality.tier {
        case .needsImprovement: return .red
        case .standard: return HennessyDesign.ColorToken.textSecondary
        case .highBitrate: return .green
        }
    }
}

private struct MediaListArtwork: View {
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
        .frame(width: HennessyDesign.Component.mediaThumbnail, height: HennessyDesign.Component.mediaThumbnail)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.7)
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: item.mode == .video || item.mode == .videoMP4
                            ? [Color(red: 0.18, green: 0.21, blue: 0.28), Color(red: 0.07, green: 0.08, blue: 0.10)]
                            : [HennessyDesign.ColorToken.accent.opacity(0.88), Color.orange.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: item.mode == .video || item.mode == .videoMP4 ? "play.rectangle" : "waveform")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
