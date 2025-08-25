import Foundation

enum ExpressionNeutralizer {
    static func neutralize(mesh: inout FaceMesh3D, blendshapes: [String: Float]) {
        // TODO: 使用表情系数反驱动到中性
        mesh.neutralPoseCoeffs = blendshapes.mapValues { _ in 0 }
    }
}


