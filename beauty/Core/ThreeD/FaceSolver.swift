import Foundation

public enum FaceSolver {
    public static func solve(from initial: FaceParams, targets: FaceParams, model: Face3DModel, calib: Float) -> (FaceParams, [EnergyBreakdown]) {
        var p = initial
        var log: [EnergyBreakdown] = []
        for _ in 0..<3 {
            let e = DeformationEnergy.total(params: p, targets: targets, weights: [:])
            log.append(e)
            // gradient descent placeholder towards targets
            p.tipRotationDeg = (p.tipRotationDeg + targets.tipRotationDeg)/2
            p.tipProjectionMM = (p.tipProjectionMM + targets.tipProjectionMM)/2
            p.dorsalStraighten = (p.dorsalStraighten + targets.dorsalStraighten)/2
            p.chinProjectionMM = (p.chinProjectionMM + targets.chinProjectionMM)/2
            p.jawlineRefine = (p.jawlineRefine + targets.jawlineRefine)/2
        }
        return (p, log)
    }
}


