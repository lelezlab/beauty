import Foundation
import AVFoundation
import ARKit

final class DynamicCaptureSession: NSObject, ObservableObject {
    enum Mode { case arFace, videoOnly }
    @Published var isRecording = false
    @Published var lastQuality: BTCaptureQC?
    private let session = AVCaptureSession()
    private var writer: AVAssetWriter?
    private var mode: Mode = .videoOnly

    func configure() {
        session.beginConfiguration()
        session.sessionPreset = .high
        if let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let input = try? AVCaptureDeviceInput(device: dev), session.canAddInput(input) {
            session.addInput(input)
        }
        session.commitConfiguration()
    }

    func start() { session.startRunning() }
    func stop() { session.stopRunning() }

    func startRecording() {
        isRecording = true
        // Placeholder: set up AVAssetWriter if needed
    }

    func stopRecording() {
        isRecording = false
        // Placeholder finalize and produce QC
        lastQuality = BTCaptureQC(blurScore: 0.8, exposureMean: 0.6, faceCoverage: 0.7, yaw: 0, pitch: 0, roll: 0, focalEq: nil, distanceBucket: 3, aeLocked: nil, awbLocked: nil, alignScore: 0.7)
    }
}


