import Foundation
import CoreGraphics

extension ProofProducer {
    func produceAIMetricsProof(mesh: FaceMesh3D?, landmarks: [CGPoint]?, outDir: URL) {
        let result = FacialAnthroKit.measureFrom(mesh: mesh, landmarks: landmarks)
        let ctx = RulesEngine.Context(gender: "F", age: 26, ethnicity: "EA")
        if let rulesURL = Bundle.main.url(forResource: "craniofacial_rules.zh", withExtension: "yaml"),
           let refsURL = Bundle.main.url(forResource: "references.bib", withExtension: "json"),
           let engine = try? RulesEngine(rulesURL: rulesURL, refsURL: refsURL) {
            let hits = engine.evaluate(measures: result.measures, ctx: ctx)
            try? MetricsRecorder.writeMetrics(result.measures, hits: hits, to: outDir)
        }
    }
}


