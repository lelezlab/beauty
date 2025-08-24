import Foundation
import AVFoundation
import ARKit
import UIKit

/// Minimal controller that simulates a short guided capture and outputs three best frames.
/// Later can be replaced with TrueDepth + fallback pipeline.
final class FaceVideoCaptureController: NSObject {
    enum Phase { case front, left, right, nod }

    var onProgress: ((Phase, Double) -> Void)?
    var onCompleted: ((UIImage, UIImage, UIImage) -> Void)?

    private var timer: Timer?
    private var running: Bool = false

    func start() {
        guard !running else { return }
        running = true
        var t: TimeInterval = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] tim in
            guard let self else { return }
            t += 0.2
            switch t {
            case ..<1.6:
                self.onProgress?(.front, min(1.0, t/1.6))
            case ..<3.2:
                self.onProgress?(.left, min(1.0, (t-1.6)/1.6))
            case ..<4.8:
                self.onProgress?(.right, min(1.0, (t-3.2)/1.6))
            case ..<6.0:
                self.onProgress?(.nod, min(1.0, (t-4.8)/1.2))
            default:
                tim.invalidate()
                self.running = false
                // Produce placeholder frames (white canvases) if camera pipeline not yet wired.
                let size = CGSize(width: 720, height: 960)
                let make: () -> UIImage = {
                    UIGraphicsBeginImageContextWithOptions(size, true, 0)
                    UIColor.white.setFill(); UIRectFill(CGRect(origin: .zero, size: size))
                    let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
                    UIGraphicsEndImageContext(); return img
                }
                self.onCompleted?(make(), make(), make())
            }
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil; running = false
    }
}


