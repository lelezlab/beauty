import Foundation

struct AestheticsSafetyConfig {
    struct Window { let min: Double; let max: Double }
    // 推荐安全区间（可按需扩展更多键）
    static var recommended: [String: Window] = {
        var dict: [String: Window] = [
            "tip_rotation": .init(min: -2, max: 8),
            "bridge_straighten": .init(min: 0.0, max: 0.7)
        ]
        // 从 UserDefaults 恢复
        let ud = UserDefaults.standard
        if let min = ud.object(forKey: "safe_tip_min") as? Double { dict["tip_rotation"] = .init(min: min, max: dict["tip_rotation"]!.max) }
        if let max = ud.object(forKey: "safe_tip_max") as? Double { dict["tip_rotation"] = .init(min: dict["tip_rotation"]!.min, max: max) }
        if let min = ud.object(forKey: "safe_bridge_min") as? Double { dict["bridge_straighten"] = .init(min: min, max: dict["bridge_straighten"]!.max) }
        if let max = ud.object(forKey: "safe_bridge_max") as? Double { dict["bridge_straighten"] = .init(min: dict["bridge_straighten"]!.min, max: max) }
        return dict
    }()
}


