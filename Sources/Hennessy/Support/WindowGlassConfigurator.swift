import AppKit
import SwiftUI

struct WindowGlassConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configure(window: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else { return }
        let minimumContentSize = NSSize(
            width: HennessyDesign.Component.windowMinimumWidth,
            height: HennessyDesign.Component.windowMinimumHeight
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.hasShadow = true
        window.contentMinSize = minimumContentSize

        guard let contentView = window.contentView else { return }
        let currentContentSize = contentView.bounds.size
        guard currentContentSize.width < minimumContentSize.width
            || currentContentSize.height < minimumContentSize.height else {
            return
        }

        window.setContentSize(NSSize(
            width: max(currentContentSize.width, minimumContentSize.width),
            height: max(currentContentSize.height, minimumContentSize.height)
        ))
    }
}
