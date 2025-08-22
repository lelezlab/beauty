import UIKit

// 三视图一致形变协调器（简化版）
// 当前实现：对三张图分别应用相同的效果控件，保证参数一致；
// 后续可以在此处加入 TPS/MLS 以及侧面参数约束（如旋转/长度映射）。
struct MultiViewMorpher {
    static func solve(front: UIImage,
                      left: UIImage,
                      right: UIImage,
                      pack: EffectPack,
                      controls: [String: Double],
                      frontLandmarks: FacialLandmarksResult?) -> (front: UIImage, left: UIImage, right: UIImage) {
        var f = EffectComposer.render(image: front, pack: pack, controls: controls, landmarks: frontLandmarks)
        let lmkL = CaptureStore.shared.leftLandmarks
        let lmkR = CaptureStore.shared.rightLandmarks
        var l = EffectComposer.render(image: left, pack: pack, controls: controls, landmarks: lmkL)
        var r = EffectComposer.render(image: right, pack: pack, controls: controls, landmarks: lmkR)

        // 轻量联动：按照 tip_rotation 在鼻尖附近做局部旋转（正面/左/右一致参数）
        if let deg = controls["tip_rotation"], abs(deg) > 0.01 {
            if let c = roiCenter(frontLandmarks, keys: ["nose", "noseCrest"]) {
                f = applyLocalRotation(to: f, center: c, radiusRatio: 0.15, degrees: deg)
            }
            if let c = roiCenter(lmkL, keys: ["nose", "noseCrest"]) {
                l = applyLocalRotation(to: l, center: c, radiusRatio: 0.15, degrees: deg)
            }
            if let c = roiCenter(lmkR, keys: ["nose", "noseCrest"]) {
                r = applyLocalRotation(to: r, center: c, radiusRatio: 0.15, degrees: deg)
            }
        }
        return (f, l, r)
    }

    /// 简单一致性评分：对鼻尖/鼻梁等 ROI 的位移幅值做相对比较（示意实现，0-1）
    static func consistencyScore(front: FacialLandmarksResult?, left: FacialLandmarksResult?, right: FacialLandmarksResult?) -> Double {
        func roiCenter(_ lmk: FacialLandmarksResult?, key: String) -> CGPoint? {
            guard let arr = lmk?.points[key], !arr.isEmpty else { return nil }
            let sx = arr.map { $0.x }.reduce(0, +)
            let sy = arr.map { $0.y }.reduce(0, +)
            return CGPoint(x: sx/CGFloat(arr.count), y: sy/CGFloat(arr.count))
        }
        // 选取三个 ROI：鼻尖(用 nose)、鼻梁(noseCrest)、下巴(faceContour 末端近似)
        let keys = ["nose", "noseCrest", "faceContour"]
        var scores: [Double] = []
        for k in keys {
            guard let cf = roiCenter(front, key: k) else { continue }
            let cl = roiCenter(left, key: k)
            let cr = roiCenter(right, key: k)
            let ds: [CGFloat] = [cl, cr].compactMap { $0 }.map { hypot($0.x - cf.x, $0.y - cf.y) }
            guard !ds.isEmpty else { continue }
            // 距离越小一致性越好；将像素归一化（假设归一化坐标 0..1）
            let avg = Double(ds.reduce(0, +)/CGFloat(ds.count))
            let s = max(0.0, min(1.0, 1.0 - avg))
            scores.append(s)
        }
        guard !scores.isEmpty else { return 0.0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    // MARK: - Helpers
    private static func roiCenter(_ lmk: FacialLandmarksResult?, keys: [String]) -> CGPoint? {
        guard let lmk else { return nil }
        var pts: [CGPoint] = []
        for k in keys { if let arr = lmk.points[k] { pts.append(contentsOf: arr) } }
        guard !pts.isEmpty else { return nil }
        let sx = pts.map { $0.x }.reduce(0, +)
        let sy = pts.map { $0.y }.reduce(0, +)
        // landmarks 为归一化坐标(0..1)，需映射到像素
        let w = lmk.boundingBox.width > 0 ? lmk.boundingBox.width : 1
        _ = w // 未使用，坐标已是图像归一化空间
        return CGPoint(x: sx/CGFloat(pts.count), y: sy/CGFloat(pts.count))
    }

    private static func applyLocalRotation(to image: UIImage, center: CGPoint, radiusRatio: CGFloat, degrees: Double) -> UIImage {
        let size = image.size
        let centerPx = CGPoint(x: center.x * size.width, y: center.y * size.height)
        let radius = min(size.width, size.height) * max(0.05, min(0.3, radiusRatio))
        let radians = CGFloat(degrees * .pi / 180.0)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // 先画原图
            image.draw(in: CGRect(origin: .zero, size: size))
            // 在鼻尖圆形区域内旋转绘制同一图像，产生局部旋转效果
            ctx.cgContext.saveGState()
            let clipPath = UIBezierPath(ovalIn: CGRect(x: centerPx.x - radius, y: centerPx.y - radius, width: radius*2, height: radius*2)).cgPath
            ctx.cgContext.addPath(clipPath)
            ctx.cgContext.clip()
            ctx.cgContext.translateBy(x: centerPx.x, y: centerPx.y)
            ctx.cgContext.rotate(by: radians)
            ctx.cgContext.translateBy(x: -centerPx.x, y: -centerPx.y)
            image.draw(in: CGRect(origin: .zero, size: size))
            ctx.cgContext.restoreGState()
        }
    }
}


