import Foundation
import simd

public struct FacialMeasures: Codable {
    public var nasolabialAngleDeg: Float?
    public var nasofrontalAngleDeg: Float?
    public var mentocervicalAngleDeg: Float?
    public var lowerThirdRatio: Float?
    public var intercanthalToEyeWidth: Float?
}

public enum MeasureQuality: String, Codable { case good, fair, poor }

public struct MeasurementResult: Codable {
    public let measures: FacialMeasures
    public let quality: MeasureQuality
    public let notes: [String]
}

public enum FacialAnthroKit {
    public static func measureFrom(mesh: FaceMesh3D?, landmarks: [CGPoint]?) -> MeasurementResult {
        var m = FacialMeasures()
        var notes: [String] = []
        if m.nasolabialAngleDeg == nil { notes.append("nasolabialAngle unavailable") }
        if m.mentocervicalAngleDeg == nil { notes.append("mentocervicalAngle unavailable") }
        let hasEnough = m.nasolabialAngleDeg != nil || m.mentocervicalAngleDeg != nil
        return MeasurementResult(measures: m, quality: hasEnough ? .fair : .poor, notes: notes)
    }
}


