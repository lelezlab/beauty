import SwiftUI
import ARKit

struct FaceCaptureView: View {
    @StateObject private var capture = DynamicCaptureSession()
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Color.black.opacity(0.05)
                Text("AR/Video Preview (placeholder)")
            }
            .frame(height: 360)
            HStack {
                Button(capture.isRecording ? "停止" : "开始录制") {
                    if capture.isRecording { capture.stopRecording() } else { capture.startRecording() }
                }
                .buttonStyle(.borderedProminent)
                if let qc = capture.lastQuality {
                    Text(String(format: "QC 模糊%.2f 曝光%.2f 覆盖%.2f", qc.blurScore, qc.exposureMean, qc.faceCoverage)).font(.caption)
                }
            }
        }
        .onAppear { capture.configure(); capture.start() }
        .onDisappear { capture.stop() }
    }
}


