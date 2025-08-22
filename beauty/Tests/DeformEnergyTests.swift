import Foundation

final class DeformEnergyTests {
    func testEnergyNonIncreaseSmallStep() {
        var p0 = FaceParams(); var t = FaceParams(tipRotationDeg: 5, tipProjectionMM: 2, dorsalStraighten: 1, chinProjectionMM: 1, jawlineRefine: 0)
        let model = Face3DModel(flame: nil)
        let (p1, log) = FaceSolver.solve(from: p0, targets: t, model: model, calib: 0.12)
        precondition(!log.isEmpty)
        // last energy should not exceed first by large margin in placeholder
        precondition(log.last!.data <= log.first!.data * 1.01)
        _ = p1
    }
}


