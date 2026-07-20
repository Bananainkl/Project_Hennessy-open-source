import SwiftUI

struct ActivityLogView: View {
    let logText: String
    let isRunning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("运行日志", systemImage: "terminal")
                    .font(HennessyDesign.Typography.cardTitle)
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary)
                Spacer()
                if isRunning {
                    Text("实时")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(HennessyDesign.ColorToken.textSecondary)
                }
            }

            ScrollView {
                Text(logText)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(HennessyDesign.ColorToken.textPrimary.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(12)
            }
            .frame(minHeight: 112, maxHeight: 170)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.30), lineWidth: 0.7)
            }
        }
        .padding(16)
        .appleMusicCard()
    }
}
