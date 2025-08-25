import UIKit

enum EffectComposer {
    static func render(image: UIImage, pack: EffectPack, controls: [String: Double], landmarks: FacialLandmarksResult?) -> UIImage {
        // 简化接入：根据常见键映射到现有渲染器参数，其他保留原图
        guard let lmk = landmarks else { return image }
        let renderer = MorphingRenderer()
        // 映射：tip_rotation/bridge_straighten/jawline_sharpness 等 → 近似到 preset 或手动调整
        let nose = CGFloat(controls["tip_rotation"] ?? 0) / 12.0
        let chin = CGFloat(controls["chin_projection"] ?? 0)
        let jaw = CGFloat(controls["jawline_sharpness"] ?? 0)
        let cheek = CGFloat(controls["zygoma_reduction"] ?? 0)
        let lips = CGFloat(controls["lip_ratio"] ?? 0)
        return renderer.applyManualAdjustments(to: renderer.applyPreset(.natural, to: image, landmarks: lmk), nose: nose, chin: chin, jaw: jaw, cheekbone: cheek, lips: lips)
    }
}


