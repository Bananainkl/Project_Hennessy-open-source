import AppKit
import SwiftUI

enum HennessyDesign {
    enum ColorToken {
        static let windowBackground = adaptive(
            light: nsColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 0.22),
            dark: nsColor(red: 0.073, green: 0.078, blue: 0.090, alpha: 0.36)
        )
        static let windowBackgroundWarm = adaptive(
            light: nsColor(red: 0.985, green: 0.982, blue: 0.976, alpha: 0.24),
            dark: nsColor(red: 0.118, green: 0.103, blue: 0.110, alpha: 0.38)
        )
        static let sidebarBackground = adaptive(
            light: nsColor(red: 0.949, green: 0.969, blue: 0.980, alpha: 0.46),
            dark: nsColor(red: 0.095, green: 0.105, blue: 0.125, alpha: 0.54)
        )
        static let cardBackground = adaptive(
            light: nsColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.30),
            dark: nsColor(red: 0.155, green: 0.165, blue: 0.190, alpha: 0.42)
        )
        static let glass = adaptive(
            light: nsColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.34),
            dark: nsColor(red: 0.235, green: 0.245, blue: 0.280, alpha: 0.42)
        )
        static let glassStrong = adaptive(
            light: nsColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.48),
            dark: nsColor(red: 0.270, green: 0.285, blue: 0.325, alpha: 0.58)
        )
        static let glassSubtle = adaptive(
            light: nsColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.20),
            dark: nsColor(red: 0.185, green: 0.195, blue: 0.230, alpha: 0.34)
        )
        static let textPrimary = adaptive(
            light: nsColor(red: 0.114, green: 0.114, blue: 0.122),
            dark: nsColor(red: 0.925, green: 0.930, blue: 0.940)
        )
        static let textSecondary = adaptive(
            light: nsColor(red: 0.431, green: 0.431, blue: 0.451),
            dark: nsColor(red: 0.680, green: 0.700, blue: 0.735)
        )
        static let textTertiary = adaptive(
            light: nsColor(red: 0.604, green: 0.604, blue: 0.620),
            dark: nsColor(red: 0.500, green: 0.520, blue: 0.555)
        )
        static let separator = adaptive(
            light: nsColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 0.08),
            dark: nsColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.14)
        )
        static let hover = adaptive(
            light: nsColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 0.04),
            dark: nsColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 0.08)
        )
        static let selected = adaptive(
            light: nsColor(red: 0.980, green: 0.176, blue: 0.333, alpha: 0.10),
            dark: nsColor(red: 0.980, green: 0.176, blue: 0.333, alpha: 0.18)
        )
        static let accent = Color(red: 0.98, green: 0.176, blue: 0.333)
        static let accentSoft = adaptive(
            light: nsColor(red: 0.980, green: 0.176, blue: 0.333, alpha: 0.12),
            dark: nsColor(red: 0.980, green: 0.176, blue: 0.333, alpha: 0.20)
        )
    }

    enum Radius {
        static let row: CGFloat = 10
        static let panel: CGFloat = 18
        static let player: CGFloat = 34
        static let control: CGFloat = 14
    }

    enum Shadow {
        static let glassColor = Color.black.opacity(0.10)
        static let cardColor = Color.black.opacity(0.045)
        static let panelRadius: CGFloat = 28
        static let cardRadius: CGFloat = 18
        static let playerRadius: CGFloat = 34
    }

    enum Spacing {
        static let contentHorizontal: CGFloat = 38
        static let contentTop: CGFloat = 34
        static let miniPlayerReserved: CGFloat = 110
        static let sidebarHorizontal: CGFloat = 16
        static let miniPlayerHorizontal: CGFloat = 38
        static let miniPlayerBottom: CGFloat = 16
        static let miniPlayerHeight: CGFloat = 68
    }

    enum Component {
        static let windowMinimumWidth: CGFloat = 1080
        static let windowMinimumHeight: CGFloat = 700
        static let sidebarMinWidth: CGFloat = 238
        static let sidebarIdealWidth: CGFloat = 258
        static let sidebarMaxWidth: CGFloat = 282
        static let sidebarRowHeight: CGFloat = 40
        static let sidebarIconSize: CGFloat = 18
        static let sidebarIconColumn: CGFloat = 20
        static let mediaRowHeight: CGFloat = 64
        static let mediaThumbnail: CGFloat = 46
        static let miniArtwork: CGFloat = 38
        static let miniVolumeWidth: CGFloat = 112
        static let miniTransportMinWidth: CGFloat = 186
        static let miniTransportIdealWidth: CGFloat = 214
        static let miniTransportMaxWidth: CGFloat = 232
        static let miniSummaryMinWidth: CGFloat = 220
        static let miniSummaryIdealWidth: CGFloat = 440
        static let miniSummaryMaxWidth: CGFloat = 520
        static let miniTrailingMinWidth: CGFloat = 206
        static let miniTrailingIdealWidth: CGFloat = 244
        static let miniTrailingMaxWidth: CGFloat = 282
    }

    enum Typography {
        static let pageTitle = Font.system(size: 36, weight: .bold, design: .default)
        static let cardTitle = Font.system(size: 15, weight: .semibold, design: .default)
        static let sectionLabel = Font.system(size: 11, weight: .semibold, design: .default)
        static let rowTitle = Font.system(size: 13, weight: .semibold, design: .default)
        static let rowSubtitle = Font.system(size: 12, weight: .regular, design: .default)
    }

    enum Player {
        enum ColorToken {
            static let backgroundTop = Color(red: 0.47, green: 0.49, blue: 0.51).opacity(0.92)
            static let backgroundBottom = Color(red: 0.30, green: 0.32, blue: 0.34).opacity(0.96)
            static let glass = Color.white.opacity(0.14)
            static let glassStrong = Color.white.opacity(0.22)
            static let glassSubtle = Color.white.opacity(0.08)
            static let textPrimary = Color.white.opacity(0.92)
            static let textSecondary = Color.white.opacity(0.62)
            static let textTertiary = Color.white.opacity(0.42)
            static let separator = Color.white.opacity(0.22)
            static let accent = Color(red: 0.98, green: 0.176, blue: 0.333)
        }

        enum Radius {
            static let large: CGFloat = 28
            static let medium: CGFloat = 18
            static let small: CGFloat = 12
        }

        enum Layout {
            static let topBarHeight: CGFloat = 66
            static let topInset: CGFloat = 12
            static let horizontalInset: CGFloat = 30
            static let columnGap: CGFloat = 80
        }
    }
}

private extension HennessyDesign.ColorToken {
    static func nsColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) -> NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.isDarkMode ? dark : light
        })
    }
}

private extension NSAppearance {
    var isDarkMode: Bool {
        bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}

extension View {
    func appleMusicWindowBackground() -> some View {
        background {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)

                LinearGradient(
                    colors: [
                        HennessyDesign.ColorToken.windowBackground,
                        HennessyDesign.ColorToken.windowBackgroundWarm,
                        Color.white.opacity(0.26)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.softLight)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.28),
                        Color.clear,
                        Color.black.opacity(0.025)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }

    func appleMusicGlassPanel(cornerRadius: CGFloat = HennessyDesign.Radius.panel) -> some View {
        glassPanel(cornerRadius: cornerRadius)
    }

    func appleMusicCard(cornerRadius: CGFloat = HennessyDesign.Radius.panel) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(HennessyDesign.ColorToken.cardBackground)
                }
        }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.8)
            }
            .shadow(color: HennessyDesign.Shadow.cardColor, radius: HennessyDesign.Shadow.cardRadius, y: 10)
    }

    func appleMusicPageSurface() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .appleMusicWindowBackground()
    }

    func appleMusicHoverPress(isHovered: Bool, isPressed: Bool, cornerRadius: CGFloat) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(isPressed ? HennessyDesign.ColorToken.selected : (isHovered ? HennessyDesign.ColorToken.hover : Color.clear))
        }
        .scaleEffect(isPressed ? 0.97 : 1)
        .animation(.smooth(duration: 0.14), value: isHovered)
        .animation(.smooth(duration: 0.12), value: isPressed)
    }
}
