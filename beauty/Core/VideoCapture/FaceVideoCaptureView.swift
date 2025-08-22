import SwiftUI

struct FaceVideoCaptureView: View {
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
                RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.15))
                    .frame(height: 320)
                Text(instruction).font(.headline)
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


