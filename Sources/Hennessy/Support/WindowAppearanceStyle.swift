import SwiftUI

enum WindowAppearanceStyle: String, CaseIterable, Identifiable {
    case glass
    case desktopTransparency

    var id: Self { self }

    var title: String {
        switch self {
        case .glass:
            "经典玻璃"
        case .desktopTransparency:
            "桌面透视"
        }
    }

    var icon: String {
        switch self {
        case .glass:
            "rectangle.fill"
        case .desktopTransparency:
            "rectangle.on.rectangle"
        }
    }

    var detail: String {
        switch self {
        case .glass:
            "柔和的系统材质背景，适合长时间使用。"
        case .desktopTransparency:
            "透出桌面内容，并使用深色玻璃保证文字和控件清晰。"
        }
    }
}

private struct WindowAppearanceStyleKey: EnvironmentKey {
    static let defaultValue = WindowAppearanceStyle.glass
}

extension EnvironmentValues {
    var windowAppearanceStyle: WindowAppearanceStyle {
        get { self[WindowAppearanceStyleKey.self] }
        set { self[WindowAppearanceStyleKey.self] = newValue }
    }
}
