import SwiftUI

struct RiskBadges: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("标定: ") + Text(CalibrationManager.shared.state.source?.rawValue ?? "未标定").bold()
            Label("一致性: 绿", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
            Label("越界: 无", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
        }
        .font(.caption)
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}


