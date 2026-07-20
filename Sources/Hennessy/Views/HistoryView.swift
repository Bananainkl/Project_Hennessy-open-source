import AppKit
import SwiftUI

struct HistoryView: View {
    @Bindable var store: DownloadStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("下载历史")
                        .font(HennessyDesign.Typography.pageTitle)
                        .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                    Text("\(store.filteredRecords.count) 条记录")
                        .font(.callout)
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                }
                Spacer()
            }

            if store.filteredRecords.isEmpty {
                ContentUnavailableView("暂无下载记录", systemImage: "clock", description: Text("完成一次下载后，文件和状态会显示在这里。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .appleMusicGlassPanel(cornerRadius: 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(store.filteredRecords.enumerated()), id: \.element.id) { index, record in
                            HistoryRow(record: record, isLast: index == store.filteredRecords.count - 1)
                                .contextMenu {
                                    if let outputURL = record.outputURL {
                                        Button("在访达中显示") {
                                            NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                                        }
                                        Button("播放") {
                                            store.playRecord(record)
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .scrollIndicators(.automatic)
                .appleMusicCard(cornerRadius: 24)
            }
        }
        .padding(.horizontal, HennessyDesign.Spacing.contentHorizontal)
        .padding(.top, HennessyDesign.Spacing.contentTop)
        .padding(.bottom, HennessyDesign.Spacing.miniPlayerReserved)
        .appleMusicWindowBackground()
        .searchable(text: $store.searchText, placement: .toolbar, prompt: "搜索历史")
    }
}

private struct HistoryRow: View {
    let record: DownloadRecord
    let isLast: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(record.succeeded ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(HennessyDesign.Typography.rowTitle)
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                    .lineLimit(1)
                Text(record.url)
                    .font(HennessyDesign.Typography.rowSubtitle)
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(record.mode.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary.opacity(0.80))
                Text(DateFormatters.history.string(from: record.startedAt))
                    .font(.caption)
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
            }
        }
        .frame(height: 68)
        .padding(.horizontal, 14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHovered ? HennessyDesign.ColorToken.hover : Color.clear)
        }
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(HennessyDesign.ColorToken.separator.opacity(isHovered ? 0 : 0.72))
                    .frame(height: 0.7)
                    .padding(.leading, 36)
            }
        }
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.14)) {
                isHovered = hovering
            }
        }
    }
}
