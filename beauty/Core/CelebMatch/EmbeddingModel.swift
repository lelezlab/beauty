import Foundation
import UIKit

/// 轻量占位的嵌入模型：
/// - 不依赖 CoreML 文件，完全本地离线可编译
/// - 将图像缩放到 16x8，按通道拼接为 16*8=128 维向量并 L2 归一化
protocol EmbeddingModel {
    func embed(_ image: UIImage) -> [Float]?
}

struct StubEmbeddingModel: EmbeddingModel {
    func embed(_ image: UIImage) -> [Float]? {
        let w = 16, h = 8
        let size = CGSize(width: w, height: h)
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cg = scaled?.cgImage, let data = cg.dataProvider?.data, let ptr = CFDataGetBytePtr(data) else { return nil }
        // 取灰度近似：R 通道
        var vec = [Float](repeating: 0, count: w*h)
        let bytesPerPixel = 4
        for y in 0..<h {
            for x in 0..<w {
                let idx = (y*cg.bytesPerRow + x*bytesPerPixel)
                let r = Float(ptr[idx]) / 255.0
                vec[y*w + x] = r
            }
        }
        // L2 归一化
        let norm = sqrt(vec.reduce(0) { $0 + $1*$1 })
        if norm > 1e-6 { vec = vec.map { $0 / norm } }
        return vec
    }
}


