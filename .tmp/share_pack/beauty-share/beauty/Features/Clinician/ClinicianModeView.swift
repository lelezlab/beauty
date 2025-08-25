import SwiftUI

struct ClinicianModeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Clinician Mode").font(.headline)
            RiskBadges()
            RoundedRectangle(cornerRadius: 12).stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(height: 240)
                .overlay(Text("三庭/五眼线与测量尺占位").font(.caption))
        }
        .padding()
    }
}


