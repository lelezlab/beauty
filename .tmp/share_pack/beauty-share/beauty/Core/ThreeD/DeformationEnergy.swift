import Foundation

public struct EnergyBreakdown { public var data: Float = 0, smooth: Float = 0, normal: Float = 0, boundary: Float = 0 }

public enum DeformationEnergy {
    public static func total(params: FaceParams, targets: FaceParams, weights: [String: Float]) -> EnergyBreakdown {
        // Placeholder: simple L2 on parameter deltas as data term
        var e = EnergyBreakdown()
        let dp = [params.tipRotationDeg - targets.tipRotationDeg,
                  params.tipProjectionMM - targets.tipProjectionMM,
                  params.dorsalStraighten - targets.dorsalStraighten,
                  params.chinProjectionMM - targets.chinProjectionMM,
                  params.jawlineRefine - targets.jawlineRefine]
        e.data = dp.map{ $0*$0 }.reduce(0,+)
        return e
    }
}


