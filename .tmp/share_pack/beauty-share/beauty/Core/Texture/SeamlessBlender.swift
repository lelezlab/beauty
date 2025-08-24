import Foundation
import UIKit
import CoreImage

/// Placeholder for OpenCV seamlessClone. Uses CoreImage blending as a fallback.
enum SeamlessBlender {
    static func blend(base: UIImage, patch: UIImage, center: CGPoint) -> UIImage {
        let ciBase = CIImage(image: base) ?? CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: base.size))
        let ciPatch = CIImage(image: patch) ?? CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: patch.size))
        let compositor = CIFilter(name: "CISourceOverCompositing")!
        let translated = ciPatch.transformed(by: CGAffineTransform(translationX: center.x - patch.size.width/2, y: center.y - patch.size.height/2))
        compositor.setValue(translated, forKey: kCIInputImageKey)
        compositor.setValue(ciBase, forKey: kCIInputBackgroundImageKey)
        let out = compositor.outputImage?.cropped(to: CGRect(origin: .zero, size: base.size)) ?? ciBase
        let ctx = CIContext()
        let cg = ctx.createCGImage(out, from: out.extent)!
        return UIImage(cgImage: cg)
    }
}



