import SwiftUI

struct LibraryMetadataEditorView: View {
    let item: LibraryMediaItem
    let save: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var artist: String

    init(item: LibraryMediaItem, save: @escaping (String, String) -> Void) {
        self.item = item
        self.save = save
        _title = State(initialValue: item.title)
        _artist = State(initialValue: item.artist ?? "")
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            VStack(alignment: .leading, spacing: 12) {
                MetadataEditField(title: "歌曲名", placeholder: "输入歌曲名", text: $title, systemImage: "music.note")
                MetadataEditField(title: "歌手", placeholder: "输入歌手名", text: $artist, systemImage: "person")
            }

            Text("保存后，列表、播放器、歌词匹配和专辑封面匹配都会使用新的歌曲名和歌手名。磁盘文件名不会被修改。")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("保存") {
                    save(trimmedTitle, artist)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedTitle.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 440)
        .background(HennessyDesign.ColorToken.windowBackground)
    }

    private var header: some View {
        HStack(spacing: 12) {
            EditorMiniArtwork(item: item)

            VStack(alignment: .leading, spacing: 3) {
                Text("编辑歌曲信息")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                Text(item.fileName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}

private struct EditorMiniArtwork: View {
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
                    case .empty, .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 46, height: 46)
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

private struct MetadataEditField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let systemImage: String
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HennessyDesign.ColorToken.textSecondary)

            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)

                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
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
            .frame(height: 38)
            .background(HennessyDesign.ColorToken.glassSubtle, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
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
}
