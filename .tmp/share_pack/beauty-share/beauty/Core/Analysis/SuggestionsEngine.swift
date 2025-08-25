import Foundation

struct Suggestion: Identifiable {
    let id = UUID()
    let title: String
    let reason: String
    let knowledgeKey: String
}

enum SuggestionsEngine {
    static func generate(from metrics: AestheticsMetrics) -> [Suggestion] {
        var items: [Suggestion] = []

        // 三庭五眼偏差
        let three = metrics.threeFacialZonesRatio
        if abs(three - 1.0) > 0.12 {
            items.append(.init(
                title: "三庭比例待优化",
                reason: "当前综合比为 \(String(format: "%.2f", three))，与标准 1.0 偏差较大",
                knowledgeKey: "threeZones"
            ))
        }

        // 鼻唇角
        let nAngle = metrics.nasolabialAngleDegrees
        if nAngle < 95 {
            items.append(.init(
                title: "鼻唇角偏小（抬高鼻尖/缩短人中）",
                reason: "鼻唇角 \(String(format: "%.1f°", nAngle))，低于 95°",
                knowledgeKey: "nasolabial"
            ))
        } else if nAngle > 110 {
            items.append(.init(
                title: "鼻唇角偏大（下降鼻尖/增加投影）",
                reason: "鼻唇角 \(String(format: "%.1f°", nAngle))，高于 110°",
                knowledgeKey: "nasolabial"
            ))
        }

        // 下巴投影
        let chin = metrics.chinProjectionRatio
        if chin < 0.9 {
            items.append(.init(
                title: "颏点后缩（下巴投影不足）",
                reason: "下巴投影比 \(String(format: "%.2f", chin))，低于 0.90",
                knowledgeKey: "chinProjection"
            ))
        }

        // 面宽高比
        let fwh = metrics.faceWidthToHeight
        if fwh > 0.80 {
            items.append(.init(
                title: "脸型偏宽（颧/下颌线优化）",
                reason: "面宽高比 \(String(format: "%.2f", fwh))，高于 0.80",
                knowledgeKey: "faceShape"
            ))
        }

        return items
    }
}


