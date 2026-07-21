import Foundation
import SwiftUI

enum DownloadMode: String, CaseIterable, Identifiable {
    case bestAudio
    case mp3
    case video
    case videoMP4

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bestAudio: "最高质量音频"
        case .mp3: "MP3"
        case .video: "原质量视频"
        case .videoMP4: "MP4 视频"
        }
    }

    var subtitle: String {
        switch self {
        case .bestAudio: "保留源站提供的最佳音频格式"
        case .mp3: "有损转换为 MP3，仅用于兼容旧设备"
        case .video: "最高质量视频与音频，默认 MKV"
        case .videoMP4: "最高质量视频与音频，转换为可播放 MP4"
        }
    }

    var icon: String {
        switch self {
        case .bestAudio: "waveform"
        case .mp3: "music.note"
        case .video: "film"
        case .videoMP4: "play.rectangle"
        }
    }

    var arguments: [String] {
        switch self {
        case .bestAudio: []
        case .mp3: ["--mp3"]
        case .video: ["--video"]
        case .videoMP4: ["--video-mp4"]
        }
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case search
    case download
    case player
    case recent
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .search: "搜索"
        case .download: "下载"
        case .player: "播放器"
        case .recent: "最近播放"
        case .history: "历史"
        }
    }

    var icon: String {
        switch self {
        case .search: "magnifyingglass"
        case .download: "arrow.down.circle"
        case .player: "play.square.stack"
        case .recent: "clock"
        case .history: "clock.arrow.circlepath"
        }
    }
}
