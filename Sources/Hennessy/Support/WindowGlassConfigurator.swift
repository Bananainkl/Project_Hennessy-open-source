import AppKit
import SwiftUI

struct WindowGlassConfigurator: NSViewRepresentable {
    let isFullPlayerPresented: Bool

    final class Coordinator {
        var windowControlFrames: [NSWindow.ButtonType: NSRect] = [:]
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configure(window: view.window, coordinator: context.coordinator)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window, coordinator: context.coordinator)
        }
    }

    private func configure(window: NSWindow?, coordinator: Coordinator) {
        guard let window else { return }
        let minimumContentSize = NSSize(
            width: HennessyDesign.Component.windowMinimumWidth,
            height: HennessyDesign.Component.windowMinimumHeight
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = isFullPlayerPresented ? .hidden : .visible
        configureWindowControls(in: window, coordinator: coordinator)
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

    private func configureWindowControls(in window: NSWindow, coordinator: Coordinator) {
        let buttonTypes: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]

        if !isFullPlayerPresented {
            window.toolbar?.isVisible = true
            window.contentView?.superview?.layoutSubtreeIfNeeded()
            coordinator.windowControlFrames = Dictionary(uniqueKeysWithValues: buttonTypes.compactMap { buttonType in
                guard let button = window.standardWindowButton(buttonType), let superview = button.superview else {
                    return nil
                }
                return (buttonType, superview.convert(button.frame, to: nil))
            })
            return
        }

        window.toolbar?.isVisible = false
        window.contentView?.superview?.layoutSubtreeIfNeeded()
        buttonTypes.forEach { buttonType in
            guard let button = window.standardWindowButton(buttonType) else { return }
            button.isHidden = false
            if let windowFrame = coordinator.windowControlFrames[buttonType], let superview = button.superview {
                button.frame = superview.convert(windowFrame, from: nil)
            }
        }
    }
}
