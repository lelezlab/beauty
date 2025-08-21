import UIKit

/// 占位实现：将根据 EffectPack 的 landmark_ops/texture_ops 生成渲染结果
/// 先回传原图，打通参数流；后续接入实际形变与纹理处理
enum EffectComposer {
    static func render(image: UIImage, pack: EffectPack, controls: [String: Double]) -> UIImage {
        // TODO: 接入 MorphingRenderer 与纹理管线
        return image
    }
}


