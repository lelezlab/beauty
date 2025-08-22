import Foundation
import CoreGraphics

public struct RangeD: Codable { public let min: Double; public let max: Double }
public struct AssessmentItem: Codable {
    public let key: String
    public let value: Double
    public let target: RangeD
    public let delta: Double
    public let suggestion: [String: Double]
}

public struct BeautyAssessment: Codable { public let items: [AssessmentItem]; public let summaryScore: Double }

enum AestheticsAssessor {
    // 基于已计算的指标生成建议
    static func assess(metrics m: AestheticsMetrics) -> BeautyAssessment {
        let cfg = AestheticsMappingConfig.shared
        var items: [AssessmentItem] = []
        // 目标区间（可配置）
        let nasolabialTarget = cfg.nasolabialTarget
        let fiveEyesTarget = cfg.fiveEyesTarget
        let threeZonesIdeal: Double = 3.0

        // 鼻唇角 → tip_rotation（正值抬尖，负值降尖），线性映射 0.5x
        let angle = Double(m.nasolabialAngleDegrees)
        let angleCenter = (nasolabialTarget.min + nasolabialTarget.max) / 2.0
        let angleDelta = angleCenter - angle
        let tipRotationSuggestion = max(-cfg.tipRotationClamp, min(cfg.tipRotationClamp, angleDelta * cfg.tipRotationPerDegree))
        let item1 = AssessmentItem(
            key: "nasolabial",
            value: angle,
            target: nasolabialTarget,
            delta: angleCenter - angle,
            suggestion: ["tip_rotation": tipRotationSuggestion]
        )
        items.append(item1)

        // 五眼比例 → bridge_straighten（偏差越大，越需要直化鼻背），映射到 0..1
        let five = Double(m.fiveEyesRatio)
        let fiveCenter = (fiveEyesTarget.min + fiveEyesTarget.max) / 2.0
        let fiveDelta = abs(five - fiveCenter)
        let bridgeAmount = max(0.0, min(1.0, fiveDelta / cfg.bridgeStraightenScale))
        let item2 = AssessmentItem(
            key: "fiveEyes",
            value: five,
            target: fiveEyesTarget,
            delta: five - fiveCenter,
            suggestion: ["bridge_straighten": bridgeAmount]
        )
        items.append(item2)

        // 三庭综合（和≈3 最理想）→ tip_rotation 轻微微调（辅助），映射到 ±4°
        let three = Double(m.threeFacialZonesRatio)
        let threeDelta = threeZonesIdeal - three
        let minorTip = max(-cfg.threeZonesAssistClamp, min(cfg.threeZonesAssistClamp, threeDelta * cfg.threeZonesAssistPerDelta))
        let item3 = AssessmentItem(
            key: "threeZones",
            value: three,
            target: RangeD(min: 2.6, max: 3.4),
            delta: threeDelta,
            suggestion: ["tip_rotation": minorTip]
        )
        items.append(item3)

        // 简易 summary：各项归一化得分平均
        func score(_ v: Double, _ r: RangeD) -> Double {
            let c = max(r.min, min(r.max, v))
            return 1.0 - abs(((c - (r.min + r.max)/2.0) / ((r.max - r.min)/2.0))) // 0..1
        }
        let s = (score(angle, nasolabialTarget) + score(five, fiveEyesTarget) + score(three, cfg.threeZonesRange)) / 3.0
        return BeautyAssessment(items: items, summaryScore: s)
    }

    static func assess(landmarks: [String: CGPoint]) -> BeautyAssessment {
        // 这里接简单示例：根据关键指标给出效果参数建议键
        // 实际计算应当基于完整 landmarks 与 MetricsCalculator 结果
        var items: [AssessmentItem] = []
        // 以几个示例建议键：tip_rotation、bridge_straighten、jawline_sharpness
        // 目标范围（示例）
        let nasolabialTarget = RangeD(min: 95, max: 105)
        let fiveEyesTarget = RangeD(min: 4.8, max: 5.2)

        // 如果提供的点集不足，返回空
        guard !landmarks.isEmpty else { return BeautyAssessment(items: [], summaryScore: 0) }
        // 仅示例：取出需要的点位近似角度/比例（生产逻辑在 MetricsCalculator）
        // 这里直接构造一个空建议示例
        let ex1 = AssessmentItem(key: "nasolabial", value: 100, target: nasolabialTarget, delta: 0, suggestion: ["tip_rotation": 0])
        let ex2 = AssessmentItem(key: "fiveEyes", value: 5.0, target: fiveEyesTarget, delta: 0, suggestion: ["bridge_straighten": 0.3])
        items.append(contentsOf: [ex1, ex2])
        return BeautyAssessment(items: items, summaryScore: 0.8)
    }
}

// 新增：风格词与“差异热点”
enum AestheticsInsights {
    struct Hotspot: Identifiable { let id: String; let title: String; let deltaMM: Double }
    static func styleWords(from m: AestheticsMetrics) -> [String] {
        var out: [String] = []
        if m.fiveEyesRatio > 5.2 { out.append("窄长脸") } else if m.fiveEyesRatio < 4.5 { out.append("宽短脸") }
        if m.nasolabialAngleDegrees > 105 { out.append("上翘鼻尖") } else if m.nasolabialAngleDegrees < 92 { out.append("下垂鼻尖") }
        if m.chinProjectionRatio > 0.22 { out.append("下巴有力") } else if m.chinProjectionRatio < 0.12 { out.append("下巴后缩") }
        return out
    }
    static func hotspots(from landmarks: FacialLandmarksResult?, imageSize: CGSize) -> [Hotspot] {
        let devs = MaskDeviationAnalyzer.analyze2D(landmarks: landmarks, imageSize: imageSize)
        return devs.sorted { $0.deltaMM > $1.deltaMM }.prefix(5).map { Hotspot(id: $0.id, title: $0.id, deltaMM: $0.deltaMM) }
    }
}


