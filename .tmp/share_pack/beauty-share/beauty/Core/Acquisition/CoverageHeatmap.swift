import CoreImage
import UIKit

struct CoverageHeatmap {
    private(set) var accum: CIImage?
    private let context = CIContext()
    private(set) var totalWeight: Float = 0

    mutating func accumulate(mask: CIImage, weight: Float) {
        guard weight > 0 else { return }
        if let a = accum {
            let wA = a.applyingFilter("CIColorMatrix", parameters: ["inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0), "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0), "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0), "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1), "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)])
            let wM = mask.applyingFilter("CIColorMatrix", parameters: ["inputRVector": CIVector(x: CGFloat(weight), y: 0, z: 0, w: 0), "inputGVector": CIVector(x: 0, y: CGFloat(weight), z: 0, w: 0), "inputBVector": CIVector(x: 0, y: 0, z: CGFloat(weight), w: 0), "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)])
            accum = wA.applyingFilter("CIAdditionCompositing", parameters: [kCIInputBackgroundImageKey: wM])
        } else {
            accum = mask.applyingFilter("CIColorMatrix", parameters: ["inputRVector": CIVector(x: CGFloat(weight), y: 0, z: 0, w: 0), "inputGVector": CIVector(x: 0, y: CGFloat(weight), z: 0, w: 0), "inputBVector": CIVector(x: 0, y: 0, z: CGFloat(weight), w: 0), "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)])
        }
        totalWeight += weight
    }

    var coverage: Float {
        guard let a = accum else { return 0 }
        let extent = a.extent
        guard let img = context.createCGImage(a, from: extent) else { return 0 }
        // 简化：取若干采样点估计覆盖率
        let w = img.width, h = img.height
        guard let data = img.dataProvider?.data as Data? else { return 0 }
        let bytes = [UInt8](data)
        var sum: Float = 0
        let stepX = max(1, w/64), stepY = max(1, h/64)
        var count = 0
        for y in stride(from: 0, to: h, by: stepY) {
            for x in stride(from: 0, to: w, by: stepX) {
                let idx = (y*w + x) * 4
                if idx+2 < bytes.count {
                    // 取 RGB 平均作为权
                    let v = (Float(bytes[idx]) + Float(bytes[idx+1]) + Float(bytes[idx+2])) / (255*3)
                    sum += min(1, v)
                    count += 1
                }
            }
        }
        return count > 0 ? sum / Float(count) : 0
    }

    var debugImage: CGImage? {
        guard let a = accum else { return nil }
        let heat = a.applyingFilter("CIFalseColor", parameters: ["inputColor0": CIColor(red: 0, green: 0, blue: 0), "inputColor1": CIColor(red: 1, green: 0, blue: 0)])
        return context.createCGImage(heat, from: heat.extent)
    }
}


