import SwiftUI

struct SettingsView: View {
    @Bindable var store: DownloadStore

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

            Section("依赖") {
                Text("应用会优先使用安装包内置的 yt-dlp 与 ffmpeg。若内置工具不可用，可通过 Homebrew 安装 yt-dlp 和 ffmpeg 作为兜底。")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 240)
        .padding()
    }
}
