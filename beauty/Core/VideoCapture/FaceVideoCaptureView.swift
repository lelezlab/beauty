import SwiftUI
import AVFoundation
import UIKit

struct FaceVideoCaptureView: View {
    @StateObject private var camera = CameraSession()
    @State private var phase: FaceVideoCaptureController.Phase = .front
    @State private var progress: Double = 0
    @State private var front: UIImage?
    @State private var left: UIImage?
    @State private var right: UIImage?
    let onFinished: (UIImage, UIImage, UIImage) -> Void

    private let controller = FaceVideoCaptureController()

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                VideoPreviewView(session: camera.captureSession)
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(instruction).font(.headline)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            ProgressView(value: progress)
            HStack {
                Button("开始") { start() }.buttonStyle(.borderedProminent)
                Button("停止") { controller.stop() }.buttonStyle(.bordered)
            }
        }
        .onDisappear { controller.stop() }
    }

    private var instruction: String {
        switch phase {
        case .front: return "请正视镜头"
        case .left: return "向左转约 30°"
        case .right: return "向右转约 30°"
        case .nod: return "轻点头 10–15°"
        }
    }

    private func start() {
        controller.onProgress = { ph, prog in
            self.phase = ph; self.progress = prog
        }
        controller.onCompleted = { f, l, r in
            self.front = f; self.left = l; self.right = r
            onFinished(f, l, r)
        }
        controller.start()
    }
}


private struct VideoPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView { PreviewUIView() }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.setSession(session)
    }

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
        func setSession(_ session: AVCaptureSession) {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
            if let connection = previewLayer.connection {
                connection.videoRotationAngle = 90
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = true
                }
            }
        }
    }
}

