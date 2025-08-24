import Foundation

enum ConfidenceEstimator {
    // 简化可信度：对齐(0.5) + 曝光(0.2) + 清晰度(0.2) + 距离(0.1)
    static func score(from qc: BTCaptureQC) -> Double {
        var s: Double = 0
        let align = clamp01(qc.alignScore ?? 0.0)
        s += 0.5 * align
        // 曝光：均值 0.0~1.0 视为曝光水平
        let expo = clamp01(qc.exposureMean)
        s += 0.2 * expo
        // 清晰度：blur 越低越好，这里按 1-blur
        let sharp = clamp01(1.0 - clamp01(qc.blurScore))
        s += 0.2 * sharp
        // 距离：bucket=3 最优，偏离越大惩罚
        let db = clamp01(1.0 - min(1.0, abs(Double(qc.distanceBucket ?? 3) - 3)/2.0))
        s += 0.1 * db
        return clamp01(s)
    }
}

private func clamp01(_ v: Double) -> Double { max(0.0, min(1.0, v)) }


