import UIKit
import simd

enum TextureBaker {
    struct BakeOptions { var size = CGSize(width: 1024, height: 1024); var poissonBlend = true }
    static func bake(bundle: CaptureBundle, mesh: inout FaceMesh3D, options: BakeOptions = .init()) throws {
        // TODO:
        // 1) 选择最佳帧：清晰度/视角/曝光
        // 2) 光照/白平衡归一化
        // 3) 投影到 UV 并渐变融合
        let renderer = UIGraphicsImageRenderer(size: options.size)
        let img = renderer.image { ctx in
            UIColor.darkGray.setFill(); ctx.fill(CGRect(origin: .zero, size: options.size))
            let s = "albedo placeholder" as NSString
            s.draw(at: CGPoint(x: 12, y: 12), withAttributes: [.foregroundColor: UIColor.white])
        }
        mesh.albedo = img
    }
}


