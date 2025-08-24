import Foundation
import UIKit
import ARKit

enum DiagnosticsSnapshotter {
    static func snapshot(mode: ProofMode) -> UIImage {
        let source: String = {
            if let meta = CaptureStore.shared.lastMesh?.metadata?["source"] as? String { return meta }
            if AppDebugFlags.forceTriView { return "triView" }
            // Default to mock when running proof
            return "mock"
        }()
        let text = [
            "ARKit available: \(ARFaceTrackingConfiguration.isSupported)",
            "Face frames cached: \(ARFaceGeometryCache.shared.lastGeometry == nil ? false : true) (\(source))",
            "Last reconstruction: \(UserDefaults.standard.bool(forKey: "last_recon_ok") ? "ok" : "error") (\(source))",
            "Parsing ready: \(UserDefaults.standard.bool(forKey: "diag_parsing_ready") ? "ok" : "missing")",
            "Depth ready: \(UserDefaults.standard.bool(forKey: "diag_depth_ready") ? "ok" : "missing")",
            "Edge provider: \(UserDefaults.standard.string(forKey: "edge_provider") ?? "-")",
            "Edge job id: \(UserDefaults.standard.string(forKey: "edge_job_id") ?? "-")",
            "Edge last_result: \(UserDefaults.standard.string(forKey: "edge_last_result") ?? "-")",
            "Source: \(source)"
        ]
        let size = CGSize(width: 640, height: 360)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemBackground.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedSystemFont(ofSize: 16, weight: .regular), .foregroundColor: UIColor.label]
            for (i, line) in text.enumerated() {
                let y = 20 + i * 50
                (line as NSString).draw(at: CGPoint(x: 16, y: y), withAttributes: attrs)
            }
        }
    }
}


