import SwiftUI

struct CalibrationBadge: View {
    @ObservedObject private var mgr = CalibrationManager.shared
    var body: some View {
        let state = mgr.state
        let label: String
        let color: Color
        if state.scaleMMPerPixel != nil {
            switch state.source {
            case .depth: label = "已标定"; color = .green
            case .card: label = "已标定"; color = .green
            case .ipd: label = "软标定"; color = .yellow
            case .none: label = "未标定"; color = .orange
            }
        } else { label = "未标定"; color = .orange }
        return Text(label)
            .font(.caption)
            .padding(6)
            .background(color.opacity(0.85), in: Capsule())
            .foregroundStyle(.white)
    }
}


