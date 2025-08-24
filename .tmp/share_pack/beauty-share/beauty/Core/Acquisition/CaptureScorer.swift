import AVFoundation
import ARKit

struct CaptureScorer {
    func blurScore(sampleBuffer: CMSampleBuffer) -> Float {
        guard let buf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return 0 }
        CVPixelBufferLockBaseAddress(buf, [])
        defer { CVPixelBufferUnlockBaseAddress(buf, []) }
        // 简化：用近似为清晰度代理（步长采样）
        let w = CVPixelBufferGetWidth(buf), h = CVPixelBufferGetHeight(buf)
        let strideX = max(1, w/64), strideY = max(1, h/64)
        var edgeCount = 0, total = 0
        // 取相邻像素强度差
        // 注意：真实实现可改为 vImage_Sobel 或 Laplacian
        for y in stride(from: 1, to: h-1, by: strideY) {
            for x in stride(from: 1, to: w-1, by: strideX) {
                total += 1
                // 近似：假定 BGRA，取 B 分量指示
                let base = CVPixelBufferGetBaseAddress(buf)!
                let bytesPerRow = CVPixelBufferGetBytesPerRow(buf)
                let idx = y*bytesPerRow + x*4
                let b = base.load(fromByteOffset: idx, as: UInt8.self)
                let bR = base.load(fromByteOffset: idx+4, as: UInt8.self)
                let diff = abs(Int(b) - Int(bR))
                if diff > 8 { edgeCount += 1 }
            }
        }
        if total == 0 { return 0 }
        return min(1, Float(edgeCount) / Float(total) * 4)
    }

    func exposureScore(sampleBuffer: CMSampleBuffer) -> Float {
        guard let buf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return 0 }
        CVPixelBufferLockBaseAddress(buf, [])
        defer { CVPixelBufferUnlockBaseAddress(buf, []) }
        let w = CVPixelBufferGetWidth(buf), h = CVPixelBufferGetHeight(buf)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buf)
        let base = CVPixelBufferGetBaseAddress(buf)!
        var bright: Float = 0
        let strideX = max(1, w/128), strideY = max(1, h/128)
        var count = 0
        for y in stride(from: 0, to: h, by: strideY) {
            for x in stride(from: 0, to: w, by: strideX) {
                let idx = y*bytesPerRow + x*4
                let r = Float(base.load(fromByteOffset: idx+2, as: UInt8.self))
                let g = Float(base.load(fromByteOffset: idx+1, as: UInt8.self))
                let b = Float(base.load(fromByteOffset: idx,   as: UInt8.self))
                bright += (r+g+b)/3
                count += 1
            }
        }
        if count == 0 { return 0 }
        let avg = bright / Float(count) / 255.0
        // 过曝/过暗扣分；中间亮度最优
        return 1 - abs(avg - 0.5) * 2
    }

    func expressionScore(blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]?) -> Float {
        guard let b = blendShapes else { return 1 }
        let keys: [ARFaceAnchor.BlendShapeLocation] = [.jawOpen, .mouthSmileLeft, .mouthSmileRight, .cheekPuff]
        var penalty: Float = 0
        for k in keys {
            if let v = b[k]?.floatValue { penalty += min(1, abs(v)) }
        }
        return max(0, 1 - penalty / Float(keys.count))
    }

    func overall(components: [Float]) -> Float {
        guard !components.isEmpty else { return 0 }
        let clamped = components.map { max(0, min(1, $0)) }
        return clamped.reduce(0, +) / Float(clamped.count)
    }
}


