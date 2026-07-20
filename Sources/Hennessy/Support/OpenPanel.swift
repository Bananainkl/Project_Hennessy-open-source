import AppKit
import Foundation

enum OpenPanel {
    @MainActor
    static func chooseDirectory(initialDirectory: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.title = "选择保存目录"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = initialDirectory
        return panel.runModal() == .OK ? panel.url : nil
    }

}
