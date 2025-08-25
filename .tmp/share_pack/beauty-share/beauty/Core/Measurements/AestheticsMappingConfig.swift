import Foundation

struct AestheticsMappingConfig {
    // 目标区间（可调整）
    var nasolabialTarget: RangeD = .init(min: 95, max: 105)
    var fiveEyesTarget: RangeD = .init(min: 4.8, max: 5.2)
    var threeZonesRange: RangeD = .init(min: 2.6, max: 3.4)

    // 映射系数/夹紧范围
    var tipRotationPerDegree: Double = 0.5 // 每 1° 差异 → tip_rotation 建议度数
    var tipRotationClamp: Double = 12
    var bridgeStraightenScale: Double = 1.0 // 五眼偏差 / 1.0 → 0..1 建议
    var threeZonesAssistPerDelta: Double = 0.8
    var threeZonesAssistClamp: Double = 4

    static var shared: AestheticsMappingConfig = {
        var cfg = AestheticsMappingConfig()
        // 预留从 UserDefaults 读取的入口（如将来需要做运行时调整）
        if let v = UserDefaults.standard.object(forKey: "am_tipRotationPerDeg") as? Double { cfg.tipRotationPerDegree = v }
        if let v = UserDefaults.standard.object(forKey: "am_tipRotationClamp") as? Double { cfg.tipRotationClamp = v }
        if let v = UserDefaults.standard.object(forKey: "am_bridgeScale") as? Double { cfg.bridgeStraightenScale = v }
        if let v = UserDefaults.standard.object(forKey: "am_threeAssist") as? Double { cfg.threeZonesAssistPerDelta = v }
        if let v = UserDefaults.standard.object(forKey: "am_threeClamp") as? Double { cfg.threeZonesAssistClamp = v }
        if let min = UserDefaults.standard.object(forKey: "am_nasoMin") as? Double,
           let max = UserDefaults.standard.object(forKey: "am_nasoMax") as? Double { cfg.nasolabialTarget = .init(min: min, max: max) }
        if let min = UserDefaults.standard.object(forKey: "am_fiveMin") as? Double,
           let max = UserDefaults.standard.object(forKey: "am_fiveMax") as? Double { cfg.fiveEyesTarget = .init(min: min, max: max) }
        if let min = UserDefaults.standard.object(forKey: "am_threeMin") as? Double,
           let max = UserDefaults.standard.object(forKey: "am_threeMax") as? Double { cfg.threeZonesRange = .init(min: min, max: max) }
        return cfg
    }()
}

enum ProcedureWeights {
    // 针对术式类别定义默认权重（控件键→权重），未知控件默认为 1.0
    static func weights(forCategory category: String) -> [String: Double] {
        switch category {
        case "nose":
            return [
                "tip_rotation": 1.2,
                "bridge_straighten": 1.1,
                "jaw_sharpen": 0.8,
                "chin_projection": 0.7
            ]
        case "chin":
            return [
                "chin_projection": 1.3,
                "jaw_sharpen": 1.0,
                "tip_rotation": 0.6
            ]
        case "jawline":
            return [
                "jaw_sharpen": 1.3,
                "chin_projection": 1.0,
                "bridge_straighten": 0.6
            ]
        case "lips":
            return [
                "lip_volume": 1.3,
                "tip_rotation": 0.7
            ]
        default:
            return [:]
        }
    }
}


