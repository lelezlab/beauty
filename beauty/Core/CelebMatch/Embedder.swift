import UIKit

protocol AnyFaceEmbedder {
    func embed(_ image: UIImage) throws -> [Float]
}

struct StubFaceEmbedder: AnyFaceEmbedder {
    func embed(_ image: UIImage) throws -> [Float] {
        return (StubEmbeddingModel().embed(image) ?? [])
    }
}

#if canImport(CoreML)
import CoreML
import Accelerate
final class FaceEmbedder: AnyFaceEmbedder {
    private let model: MLModel
    init?() {
        guard let url = Bundle.main.url(forResource: "ArcFace", withExtension: "mlmodelc"), let m = try? MLModel(contentsOf: url) else { return nil }
        self.model = m
    }
    func embed(_ image: UIImage) throws -> [Float] {
        guard let buf = image.pixelBuffer(width: 112, height: 112) else { return [] }
        let input = MLDictionaryFeatureProvider(dictionary: ["input": buf])
        let out = try model.prediction(from: input)
        guard let a = out.featureValue(for: "output")?.multiArrayValue else { return [] }
        var v = (0..<a.count).map { Float(truncating: a[$0]) }
        var norm: Float = 0; vDSP_svesq(v, 1, &norm, vDSP_Length(v.count)); norm = sqrtf(norm); if norm > 1e-6 { v = v.map { $0 / norm } }
        return v
    }
}
#endif

extension UIImage {
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: true, kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary
        var pb: CVPixelBuffer?
        guard kCVReturnSuccess == CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pb), let px = pb else { return nil }
        CVPixelBufferLockBaseAddress(px, [])
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(px), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(px), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
        ctx.interpolationQuality = .high
        if let cg = self.cgImage { ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height)) }
        CVPixelBufferUnlockBaseAddress(px, [])
        return px
    }
}


