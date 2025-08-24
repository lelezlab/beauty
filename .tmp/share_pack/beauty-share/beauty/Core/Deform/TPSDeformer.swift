import UIKit

public struct Anchor { public let src: CGPoint; public let dst: CGPoint }

public enum TPSDeformer {
    // Lightweight radial-basis displacement warp (TPS-like, not exact TPS).
    // Suitable for small local edits; anchors are in pixel coordinates.
    public static func warp(image: UIImage, anchors: [Anchor]) -> UIImage {
        guard let cg = image.cgImage, !anchors.isEmpty else { return image }
        let width = cg.width, height = cg.height
        guard let inData = cg.dataProvider?.data, let inPtr = CFDataGetBytePtr(inData) else { return image }
        let bytesPerPixel = 4
        let bytesPerRow = cg.bytesPerRow
        let outBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: height * bytesPerRow)
        defer { outBytes.deallocate() }

        // Precompute anchor displacements
        let disps: [(CGPoint, CGVector)] = anchors.map { (a) in (a.src, CGVector(dx: a.dst.x - a.src.x, dy: a.dst.y - a.src.y)) }
        let sigma: CGFloat = max(8, min(CGFloat(min(width, height)) * 0.12, 48))
        let twoSigma2: CGFloat = 2 * sigma * sigma

        @inline(__always) func sample(_ x: CGFloat, _ y: CGFloat) -> (UInt8, UInt8, UInt8, UInt8) {
            // Bilinear sampling from source image (clamped)
            let fx = max(0, min(CGFloat(width - 1), x))
            let fy = max(0, min(CGFloat(height - 1), y))
            let x0 = Int(floor(fx)), y0 = Int(floor(fy))
            let x1 = min(width - 1, x0 + 1), y1 = min(height - 1, y0 + 1)
            let dx = fx - CGFloat(x0), dy = fy - CGFloat(y0)
            func px(_ ix: Int, _ iy: Int) -> (Float, Float, Float, Float) {
                let off = iy * bytesPerRow + ix * bytesPerPixel
                let b = Float(inPtr[off + 0])
                let g = Float(inPtr[off + 1])
                let r = Float(inPtr[off + 2])
                let a = Float(inPtr[off + 3])
                return (r, g, b, a)
            }
            let (r00,g00,b00,a00) = px(x0,y0)
            let (r10,g10,b10,a10) = px(x1,y0)
            let (r01,g01,b01,a01) = px(x0,y1)
            let (r11,g11,b11,a11) = px(x1,y1)
            func lerp(_ a: Float,_ b: Float,_ t: CGFloat) -> Float { a + (b - a) * Float(t) }
            let r0 = lerp(r00, r10, dx), r1 = lerp(r01, r11, dx)
            let g0 = lerp(g00, g10, dx), g1 = lerp(g01, g11, dx)
            let b0 = lerp(b00, b10, dx), b1 = lerp(b01, b11, dx)
            let a0 = lerp(a00, a10, dx), a1 = lerp(a01, a11, dx)
            let r = lerp(r0, r1, dy), g = lerp(g0, g1, dy), b = lerp(b0, b1, dy), a = lerp(a0, a1, dy)
            return (UInt8(max(0, min(255, Int(b)))), UInt8(max(0, min(255, Int(g)))), UInt8(max(0, min(255, Int(r)))), UInt8(max(0, min(255, Int(a)))))
        }

        for y in 0..<height {
            let row = outBytes.advanced(by: y * bytesPerRow)
            for x in 0..<width {
                let p = CGPoint(x: x, y: y)
                // Weighted displacement
                var dx: CGFloat = 0, dy: CGFloat = 0, wsum: CGFloat = 0
                for (c, v) in disps {
                    let d2 = (p.x - c.x)*(p.x - c.x) + (p.y - c.y)*(p.y - c.y)
                    let w = exp(-d2 / twoSigma2)
                    dx += w * v.dx; dy += w * v.dy; wsum += w
                }
                if wsum > 1e-6 { dx /= wsum; dy /= wsum }
                let sx = CGFloat(x) - dx
                let sy = CGFloat(y) - dy
                let (b,g,r,a) = sample(sx, sy)
                let off = x * bytesPerPixel
                row[off + 0] = b
                row[off + 1] = g
                row[off + 2] = r
                row[off + 3] = a
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: outBytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue), let outCG = ctx.makeImage() else { return image }
        return UIImage(cgImage: outCG, scale: image.scale, orientation: image.imageOrientation)
    }
}


