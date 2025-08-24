import Foundation

enum ParamMapping {
    // effect control id -> ParametricFace field id
    static let controlToParam: [String: String] = [
        "tip_rotation": "tipRotationDeg",
        "tip_projection": "tipProjectionMM",
        "bridge_straighten": "dorsalStraighten",
        "chin_projection": "chinProjectionMM",
        "jaw_sharpen": "jawlineRefine"
    ]
}


