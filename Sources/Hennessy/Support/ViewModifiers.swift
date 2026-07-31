import SwiftUI

extension View {
    @ViewBuilder
    func glassPanel(cornerRadius: CGFloat = 24) -> some View {
        if #available(macOS 26.0, *) {
            self
                .padding(0)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.045))
                }
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.08),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                        .allowsHitTesting(false)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.10), radius: 14, y: 7)
        }
    }

    @ViewBuilder
    func subtleGlass(cornerRadius: CGFloat = 16, selected: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(selected ? Color.white.opacity(0.14) : Color.white.opacity(0.045))
                }
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(selected ? 0.24 : 0.14),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                        .allowsHitTesting(false)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(selected ? Color.white.opacity(0.34) : Color.white.opacity(0.14), lineWidth: 1)
                }
        } else {
            self
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(selected ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.04))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(selected ? Color.accentColor.opacity(0.65) : Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    func toolbarDownloadButtonStyle(isActive: Bool) -> some View {
        if #available(macOS 26.0, *) {
            self
                .buttonStyle(.borderless)
                .foregroundStyle(isActive ? .primary : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassEffect(isActive ? .regular.interactive() : .regular, in: .capsule)
        } else {
            if isActive {
                self.buttonStyle(.borderedProminent)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }

    func liquidGlassBackdrop(style: WindowAppearanceStyle = .glass) -> some View {
        background {
            LiquidGlassBackdrop(style: style)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    func downloadActionButtonStyle(isActive: Bool) -> some View {
        if #available(macOS 26.0, *) {
            self
                .buttonStyle(.borderless)
                .foregroundStyle(isActive ? .primary : .secondary)
                .controlSize(.large)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .glassEffect(isActive ? .regular.interactive() : .regular, in: .capsule)
        } else {
            if isActive {
                self
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
            } else {
                self
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
            }
        }
    }

    func liquidGlassActionChip(selected: Bool = false, width: CGFloat? = nil, height: CGFloat = 40) -> some View {
        modifier(LiquidGlassActionChipModifier(selected: selected, width: width, height: height))
    }

    func liquidGlassSelectionChip(selected: Bool) -> some View {
        modifier(LiquidGlassSelectionChipModifier(selected: selected))
    }

    @ViewBuilder
    func albumArtworkRefreshButtonStyle(isActive: Bool) -> some View {
        if #available(macOS 26.0, *) {
            self
                .buttonStyle(.borderless)
                .labelStyle(.titleAndIcon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? .primary : .secondary)
                .frame(width: 126, height: 38)
                .contentShape(Capsule())
                .glassEffect(isActive ? .regular.interactive() : .regular, in: .capsule)
        } else {
            self
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .buttonBorderShape(.capsule)
                .frame(width: 126)
        }
    }

    func flatIconActionButton(width: CGFloat = 56, height: CGFloat = 42) -> some View {
        modifier(FlatIconActionButtonModifier(width: width, height: height))
    }
}

private struct LiquidGlassActionChipModifier: ViewModifier {
    let selected: Bool
    let width: CGFloat?
    let height: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .focusable(false)
                .buttonStyle(LiquidGlassActionButtonStyle(selected: selected, hovered: isHovered, width: width, height: height))
                .onHover { hovering in
                    withAnimation(.smooth(duration: 0.16)) {
                        isHovered = hovering
                    }
                }
        } else {
            content
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .buttonBorderShape(.capsule)
        }
    }
}

private struct LiquidGlassSelectionChipModifier: ViewModifier {
    let selected: Bool
    @State private var isHovered = false

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .focusable(false)
                .buttonStyle(LiquidGlassSelectionButtonStyle(selected: selected, hovered: isHovered))
                .onHover { hovering in
                    withAnimation(.smooth(duration: 0.16)) {
                        isHovered = hovering
                    }
                }
        } else if selected {
            content
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            content
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct FlatIconActionButtonModifier: ViewModifier {
    let width: CGFloat
    let height: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .focusable(false)
            .buttonStyle(FlatIconActionButtonStyle(hovered: isHovered, width: width, height: height))
            .onHover { hovering in
                withAnimation(.smooth(duration: 0.14)) {
                    isHovered = hovering
                }
            }
    }
}

private struct FlatIconActionButtonStyle: ButtonStyle {
    let hovered: Bool
    let width: CGFloat
    let height: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: width, height: height)
            .contentShape(Capsule())
            .background {
                Capsule()
                    .fill(.thinMaterial)
                    .opacity(hovered || configuration.isPressed ? 0.70 : 0.42)
            }
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(hovered ? 0.30 : 0.14), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : (hovered ? 1.02 : 1))
            .animation(.smooth(duration: 0.14), value: configuration.isPressed)
            .animation(.smooth(duration: 0.14), value: hovered)
    }
}

@available(macOS 26.0, *)
private struct LiquidGlassActionButtonStyle: ButtonStyle {
    let selected: Bool
    let hovered: Bool
    let width: CGFloat?
    let height: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .controlSize(.regular)
            .foregroundStyle(.primary)
            .labelStyle(.iconOnly)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: width, height: height)
            .contentShape(Capsule())
            .background {
                Capsule()
                    .fill(Color.white.opacity(backgroundOpacity(isPressed: configuration.isPressed)))
            }
            .glassEffect(.regular.interactive(), in: .capsule)
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(hovered || selected ? 0.26 : 0.12), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
                    .allowsHitTesting(false)
            }
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(borderOpacity(isPressed: configuration.isPressed)), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.965 : (hovered ? 1.035 : 1))
            .brightness(configuration.isPressed ? 0.07 : (hovered ? 0.045 : 0))
            .animation(.smooth(duration: 0.16), value: configuration.isPressed)
            .animation(.smooth(duration: 0.18), value: selected)
            .animation(.smooth(duration: 0.16), value: hovered)
    }

    private func backgroundOpacity(isPressed: Bool) -> Double {
        if selected {
            return isPressed ? 0.22 : (hovered ? 0.18 : 0.13)
        }
        return isPressed ? 0.16 : (hovered ? 0.105 : 0.055)
    }

    private func borderOpacity(isPressed: Bool) -> Double {
        if selected {
            return isPressed ? 0.50 : (hovered ? 0.42 : 0.34)
        }
        return isPressed ? 0.42 : (hovered ? 0.30 : 0.18)
    }
}

@available(macOS 26.0, *)
private struct LiquidGlassSelectionButtonStyle: ButtonStyle {
    let selected: Bool
    let hovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(selected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Capsule())
            .background {
                Capsule()
                    .fill(backgroundOpacity(isPressed: configuration.isPressed))
            }
            .glassEffect(selected || configuration.isPressed ? .regular.interactive() : .regular, in: .capsule)
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(selected || hovered ? 0.26 : 0.10), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
                    .allowsHitTesting(false)
            }
            .overlay {
                Capsule()
                    .strokeBorder(borderOpacity(isPressed: configuration.isPressed), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.972 : (hovered ? 1.025 : 1))
            .brightness(configuration.isPressed ? 0.07 : (hovered ? 0.04 : 0))
            .animation(.smooth(duration: 0.18), value: selected)
            .animation(.smooth(duration: 0.14), value: configuration.isPressed)
            .animation(.smooth(duration: 0.16), value: hovered)
    }

    private func backgroundOpacity(isPressed: Bool) -> Color {
        if selected {
            return Color.white.opacity(isPressed ? 0.22 : (hovered ? 0.17 : 0.13))
        }
        return Color.white.opacity(isPressed ? 0.13 : (hovered ? 0.075 : 0.035))
    }

    private func borderOpacity(isPressed: Bool) -> Color {
        if selected {
            return Color.white.opacity(isPressed ? 0.48 : (hovered ? 0.40 : 0.34))
        }
        return Color.white.opacity(isPressed ? 0.32 : (hovered ? 0.22 : 0.12))
    }
}

private struct LiquidGlassBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let style: WindowAppearanceStyle

    var body: some View {
        if style == .desktopTransparency && !reduceTransparency {
            ZStack {
                Color.clear
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.46)
                Color.black.opacity(0.16)
                LinearGradient(
                    colors: [Color.white.opacity(0.10), .clear, Color.black.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            classicBackdrop
        }
    }

    private var classicBackdrop: some View {
        ZStack {
            Color.clear

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.68 : 0.86)

            LinearGradient(
                colors: [
                    colorScheme == .dark ? Color(red: 0.13, green: 0.11, blue: 0.12) : Color(red: 0.82, green: 0.88, blue: 0.96),
                    colorScheme == .dark ? Color(red: 0.18, green: 0.16, blue: 0.14) : Color(red: 0.98, green: 0.97, blue: 0.91),
                    colorScheme == .dark ? Color(red: 0.11, green: 0.12, blue: 0.15) : Color(red: 0.88, green: 0.86, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(colorScheme == .dark ? 0.48 : 0.22)

            LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.035 : 0.30),
                    Color.white.opacity(colorScheme == .dark ? 0.06 : 0.38),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.softLight)

            Rectangle()
                .fill(.thinMaterial)
                .opacity(colorScheme == .dark ? 0.12 : 0.28)
        }
    }
}
