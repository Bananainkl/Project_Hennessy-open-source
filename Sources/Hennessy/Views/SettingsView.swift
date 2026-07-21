import SwiftUI

struct SettingsView: View {
    @Bindable var store: DownloadStore
    @State private var showsUpgradeConfirmation = false

    var body: some View {
        Form {
            Section("默认保存") {
                HStack {
                    Text(store.outputDirectory.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("选择") {
                        store.chooseOutputDirectory()
                    }
                }
            }

            Section("音质核验") {
                LabeledContent("已检测", value: "\(store.auditedAudioCount) 首")
                LabeledContent("需要改善", value: "\(store.audioItemsNeedingImprovement.count) 首")
                LabeledContent("MP3 二次转码", value: "\(store.transcodedMP3Count) 首")
                if let progress = store.audioQualityAuditProgress, store.isAudioQualityAuditRunning {
                    ProgressView(value: progress)
                }
                Text(store.audioQualityStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button(store.isAudioQualityAuditRunning ? "检测中" : "重新检测") {
                        store.startAudioQualityAudit()
                    }
                    .disabled(store.isAudioQualityAuditRunning || store.isRunning)
                    Button(store.isAudioQualityUpgradeRunning ? "改善中" : "安全重下低音质文件") {
                        showsUpgradeConfirmation = true
                    }
                    .disabled(!store.canUpgradeLowQualityAudio)
                }
                if store.isAudioQualityUpgradeRunning, let progress = store.downloadProgress {
                    ProgressView(value: progress)
                }
                if let summary = store.audioQualityUpgradeSummary {
                    Text(summary).font(.caption).foregroundStyle(.secondary)
                }
                Text("只会在新文件达到至少 120 kbps 且明显优于原文件时替换。原文件会移入同目录的“Hennessy Quality Backups”，正在播放的文件会跳过。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("依赖") {
                Text("应用会优先使用安装包内置的 yt-dlp 与 ffmpeg。若内置工具不可用，可通过 Homebrew 安装 yt-dlp 和 ffmpeg 作为兜底。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(
            "安全重下 \(store.audioItemsNeedingImprovement.count) 首低音质文件？",
            isPresented: $showsUpgradeConfirmation,
            titleVisibility: .visible
        ) {
            Button("开始安全重下") { store.upgradeLowQualityAudio() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("只替换通过音质核验的文件，原文件会移入可恢复的备份目录。下载时间和流量取决于曲目数量。")
        }
        .frame(width: 560, height: 520)
        .padding()
    }
}
