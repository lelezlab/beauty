import Foundation
import UIKit
import ARKit

enum DiagnosticsSnapshotter {
    static func snapshot(mode: ProofMode) -> UIImage {
        let text = [
            "ARKit available: \(ARFaceTrackingConfiguration.isSupported)",
            "Face frames cached: \(ARFaceGeometryCache.shared.lastGeometry == nil ? false : true)",
            "Last reconstruction: \(UserDefaults.standard.bool(forKey: \"last_recon_ok\") ? \"ok\" : \"error\")"
        ]
        let size = CGSize(width: 640, height: 180)
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


