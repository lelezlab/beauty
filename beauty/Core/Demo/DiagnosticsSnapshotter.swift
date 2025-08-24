import Foundation
import UIKit
import ARKit

enum DiagnosticsSnapshotter {
    static func snapshot(mode: ProofMode) -> UIImage {
        let size = CGSize(width: 720, height: 480)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)]
            let now = Date()
            ("Diagnostics – \(now)" as NSString).draw(at: CGPoint(x: 16, y: 14), withAttributes: attrs)
            var y: CGFloat = 40
            func line(_ s: String) { (s as NSString).draw(at: CGPoint(x: 16, y: y), withAttributes: attrs); y += 16 }
            line("mode: \(mode)")
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
            for (i, line) in text.enumerated() {
                let y = 20 + i * 50
                (line as NSString).draw(at: CGPoint(x: 16, y: y), withAttributes: attrs)
            }
            // Latency percentiles
            let stat = LatencyTracker.snapshot()
            if let l = stat["landmarks_ms"], let p50 = l["p50_ms"], let p95 = l["p95_ms"] { line(String(format: "landmarks p50=%.1fms p95=%.1fms", p50, p95)) }
            if let l = stat["parsing_ms"], let p50 = l["p50_ms"], let p95 = l["p95_ms"] { line(String(format: "parsing p50=%.1fms p95=%.1fms", p50, p95)) }
        }
    }
}


