import Foundation
import UIKit

enum ParsingDepthMasker {
    /// Returns a binary mask (UIImage) where face regions are kept and non-face (ears/hair/neck) removed; depth may refine edges
    static func buildMask(from image: UIImage) async -> UIImage? {
        let parsing = await FaceParsingClient.parse(image)
        let depth = await DepthClient.infer(image)
        // Simple fallback: if parsing unavailable, return nil to skip masking
        guard parsing != nil else { return nil }
        // Placeholder: just return a soft circular mask centered; future: refine by parsing+depth
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let mask = renderer.image { ctx in
            UIColor.black.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setFill(); UIBezierPath(ovalIn: CGRect(x: size.width*0.1, y: size.height*0.05, width: size.width*0.8, height: size.height*0.9)).fill()
        }
        UserDefaults.standard.set(parsing != nil, forKey: "diag_parsing_ready")
        UserDefaults.standard.set(depth != nil, forKey: "diag_depth_ready")
        return mask
    }
}


