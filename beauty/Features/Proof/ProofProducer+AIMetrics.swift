import Foundation
import CoreGraphics

// 如果这些类型不在同一 module，请改成 public 或加 @testable import
// FaceMesh3D / FacialAnthroKit / RulesEngine / MetricsRecorder 已在 ai/* 下

extension ProofProducer {
    /// 产出 AI 指标与规则命中，写入 outDir 下的 metrics.json / rules_hits.json
    func produceAIMetricsProof(mesh: FaceMesh3D?,
                               landmarks: [CGPoint]?,
                               outDir: URL) {
        // 1) 计算测量值
        let result = FacialAnthroKit.measureFrom(mesh: mesh, landmarks: landmarks)

        // 2) 载入规则（先从 Bundle，失败则忽略规则只写 metrics）
        var hits: [RuleHit] = []
        if let rulesURL = Bundle.main.url(forResource: "craniofacial_rules.zh", withExtension: "yaml"),
           let refsURL  = Bundle.main.url(forResource: "references.bib", withExtension: "json"),
           let engine   = try? RulesEngine(rulesURL: rulesURL, refsURL: refsURL) {
            let ctx = RulesEngine.Context(gender: "F", age: 26, ethnicity: "EA")
            hits = engine.evaluate(measures: result.measures, ctx: ctx)
        }

        // 3) 落盘（目录不存在会自动创建）
        try? MetricsRecorder.writeMetrics(result.measures, hits: hits, to: outDir)
    }
}


