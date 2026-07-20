import AppKit
import SwiftUI

@main
struct HennessyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = DownloadStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .frame(
                    minWidth: HennessyDesign.Component.windowMinimumWidth,
                    minHeight: HennessyDesign.Component.windowMinimumHeight
                )
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("开始下载") {
                    store.startDownload()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!store.canStartDownload)

                Button("停止下载") {
                    store.cancelDownload()
                }
                .keyboardShortcut(".", modifiers: .command)
                .disabled(!store.isRunning)
            }
        }

        Settings {
            SettingsView(store: store)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
