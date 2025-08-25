import Foundation

public struct ParametricFace: Codable {
    public var tipRotationDeg: Double = 0
    public var tipProjectionMM: Double = 0
    public var dorsalStraighten: Double = 0
    public var chinProjectionMM: Double = 0
    public var jawlineRefine: Double = 0

    public init() {}

    public mutating func apply(id: String, value: Double) {
        switch id {
        case "tipRotationDeg": tipRotationDeg = value
        case "tipProjectionMM": tipProjectionMM = value
        case "dorsalStraighten": dorsalStraighten = value
        case "chinProjectionMM": chinProjectionMM = value
        case "jawlineRefine": jawlineRefine = value
        default: break
        }
    }

    public func asDictionary() -> [String: Double] {
        [
            "tipRotationDeg": tipRotationDeg,
            "tipProjectionMM": tipProjectionMM,
            "dorsalStraighten": dorsalStraighten,
            "chinProjectionMM": chinProjectionMM,
            "jawlineRefine": jawlineRefine
        ]
    }
}


