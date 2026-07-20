import Foundation

struct DownloadRequest: Equatable {
    var url: String
    var outputDirectory: URL
    var mode: DownloadMode
    var titleOverride: String
    var artistOverride: String
    var allowPlaylist: Bool
    var thumbnailURL: String?
}

struct DownloadRecord: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let url: String
    let outputURL: URL?
    let mode: DownloadMode
    let startedAt: Date
    let succeeded: Bool

    var statusText: String {
        succeeded ? "完成" : "失败"
    }
}

struct DownloadResult: Equatable {
    var exitCode: Int32
    var outputText: String
    var errorText: String
    var thumbnailURL: String?
    var songTitle: String?
    var artistName: String?

    var succeeded: Bool {
        exitCode == 0
    }

    var finalURL: URL? {
        let merged = outputText
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .reversed()

        for line in merged {
            if line.hasPrefix("/") {
                return URL(fileURLWithPath: line)
            }
            if let range = line.range(of: "下载完成：") {
                let path = String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                return URL(fileURLWithPath: path)
            }
            if let range = line.range(of: "预计保存为：") {
                let path = String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
