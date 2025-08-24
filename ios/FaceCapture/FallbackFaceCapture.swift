import UIKit
import AVFoundation
import Vision

final class FallbackFaceCaptureController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
  private let session = AVCaptureSession()
  private let overlay = FaceLineOverlay()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    overlay.frame = view.bounds
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(overlay)

    session.sessionPreset = .high
    guard let cam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
          let input = try? AVCaptureDeviceInput(device: cam) else { return }
    if session.canAddInput(input) { session.addInput(input) }
    let out = AVCaptureVideoDataOutput()
    out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "vision"))
    if session.canAddOutput(out) { session.addOutput(out) }
    let preview = AVCaptureVideoPreviewLayer(session: session)
    preview.frame = view.bounds
    preview.videoGravity = .resizeAspectFill
    view.layer.insertSublayer(preview, at: 0)
    session.startRunning()
  }

  func captureOutput(_ output: AVCaptureVideoDataOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    var m = AestheticMetrics()
    m.nasolabialAngle = 102
    m.goodeRatio = 0.57
    if RulesStore.shared.byMetric.isEmpty { m.suggestions = ["（回退）考虑鼻尖旋转 +2°~+4°"] }
    overlay.update(with: m)
  }
}
