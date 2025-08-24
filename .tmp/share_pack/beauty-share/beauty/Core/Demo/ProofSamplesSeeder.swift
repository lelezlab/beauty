import Foundation
import UIKit

enum ProofSamplesSeeder {
    static func seedIfNeeded() {
        let fm = FileManager.default
        let dir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("proof_samples", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let targets = [
            ("tri_front.jpg", "FRONT", UIColor.systemTeal),
            ("tri_left.jpg",  "LEFT",  UIColor.systemBlue),
            ("tri_right.jpg", "RIGHT", UIColor.systemGreen)
        ]
        for (name, label, color) in targets {
            let url = dir.appendingPathComponent(name)
            if !fm.fileExists(atPath: url.path) {
                if let img = synthesize(label: label, color: color), let data = img.jpegData(compressionQuality: 0.9) {
                    try? data.write(to: url)
                }
            }
        }
    }

    private static func synthesize(label: String, color: UIColor) -> UIImage? {
        let size = CGSize(width: 720, height: 960)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 64),
                .foregroundColor: UIColor.white
            ]
            let text = label as NSString
            let bounds = text.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
            let p = CGPoint(x: (size.width - bounds.width)/2, y: (size.height - bounds.height)/2)
            text.draw(at: p, withAttributes: attrs)
        }
    }
}



