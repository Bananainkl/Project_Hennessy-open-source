import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, HennessyDesign.Spacing.sidebarHorizontal)
                .padding(.top, 28)
                .padding(.bottom, 10)

            sidebarGroup("媒体资料库", items: [.search, .download])
            sidebarGroup("资料库", items: [.player, .recent])
            sidebarGroup("记录", items: [.history])

            Spacer(minLength: 24)
        }
        .frame(
            minWidth: HennessyDesign.Component.sidebarMinWidth,
            idealWidth: HennessyDesign.Component.sidebarIdealWidth,
            maxWidth: HennessyDesign.Component.sidebarMaxWidth,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background {
            SidebarGlassBackground()
            .ignoresSafeArea(.container, edges: [.top, .bottom])
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(HennessyDesign.ColorToken.separator)
                .frame(width: 0.7)
        }
    }

    private var header: some View {
        Text("Hennessy")
            .font(.system(size: 27, weight: .bold))
            .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
    }

    private func sidebarGroup(_ title: String?, items: [SidebarSection]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title {
                Text(title)
                    .font(HennessyDesign.Typography.sectionLabel)
                    .foregroundStyle(HennessyDesign.ColorToken.textSecondary.opacity(0.78))
                    .textCase(.uppercase)
                    .padding(.horizontal, HennessyDesign.Spacing.sidebarHorizontal)
                    .padding(.top, 18)
                    .padding(.bottom, 4)
            }

            ForEach(items) { item in
                SidebarRow(item: item, isSelected: selection == item) {
                    selection = item
                }
                .padding(.horizontal, HennessyDesign.Spacing.sidebarHorizontal)
            }
        }
    }

}

private struct SidebarGlassBackground: View {
    @Environment(\.windowAppearanceStyle) private var appearanceStyle
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if appearanceStyle == .desktopTransparency && !reduceTransparency {
            Color.clear
        } else {
            classicBackground
        }
    }

    private var classicBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            Rectangle()
                .fill(HennessyDesign.ColorToken.sidebarBackground.opacity(0.30))

            LinearGradient(
                colors: [Color.white.opacity(0.24), Color.white.opacity(0.08), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.025)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct SidebarRow: View {
    let item: SidebarSection
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isSelected ? HennessyDesign.ColorToken.accent : Color.clear)
                    .frame(width: 3, height: 22)

                Image(systemName: item.icon)
                    .font(.system(size: HennessyDesign.Component.sidebarIconSize, weight: .semibold))
                    .frame(width: HennessyDesign.Component.sidebarIconColumn)
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? HennessyDesign.ColorToken.accent : HennessyDesign.ColorToken.textPrimary)
            .frame(height: HennessyDesign.Component.sidebarRowHeight)
            .padding(.leading, 9)
            .padding(.trailing, 12)
            .contentShape(RoundedRectangle(cornerRadius: HennessyDesign.Radius.row, style: .continuous))
        }
        .buttonStyle(SidebarRowButtonStyle(isSelected: isSelected, isHovered: isHovered))
        .accessibilityLabel(item.title)
        .accessibilityIdentifier("sidebar-\(item.rawValue)")
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.14)) {
                isHovered = hovering
            }
        }
    }
}

private struct SidebarRowButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: HennessyDesign.Radius.row, style: .continuous)
                    .fill(background(isPressed: configuration.isPressed))
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .brightness(configuration.isPressed ? 0.03 : 0)
            .animation(.smooth(duration: 0.12), value: configuration.isPressed)
            .animation(.smooth(duration: 0.14), value: isHovered)
            .animation(.smooth(duration: 0.16), value: isSelected)
    }

    private func background(isPressed: Bool) -> Color {
        if isSelected {
            return HennessyDesign.ColorToken.accentSoft.opacity(isPressed ? 0.88 : 0.70)
        }
        if isPressed {
            return HennessyDesign.ColorToken.hover.opacity(1.25)
        }
        if isHovered {
            return HennessyDesign.ColorToken.hover.opacity(0.72)
        }
        return .clear
    }
}
