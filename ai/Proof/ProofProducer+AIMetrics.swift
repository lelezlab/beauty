import Foundation
import CoreGraphics
import CoreVideo

extension ProofProducer {
    func produceAIMetricsProof(mesh: FaceMesh3D?, landmarks: [CGPoint]?, outDir: URL) {
        let result = FacialAnthroKit.measureFrom(mesh: mesh, landmarks: landmarks)
        let ctx = RulesEngine.Context(gender: "F", age: 26, ethnicity: "EA")
        guard
            let rulesURL = Bundle.main.url(forResource: "craniofacial_rules.zh", withExtension: "yaml"),
            let refsURL = Bundle.main.url(forResource: "references.bib", withExtension: "json"),
            let engine = try? RulesEngine(rulesURL: rulesURL, refsURL: refsURL)
        else {
            DebugLog.log("Rules engine init failed")
            return
        }
        let hits = engine.evaluate(measures: result.measures, ctx: ctx)
        try? MetricsRecorder.writeMetrics(result.measures, hits: hits, to: outDir)
        DebugLog.log("AI metrics proof written to \(outDir.path)")
    }
}


