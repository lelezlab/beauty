import Foundation
import AVFoundation
import ARKit
import CoreImage
import UIKit

final class GuidedCaptureCoordinator: NSObject {
    private let scorer = CaptureScorer()
    private var heatmap = CoverageHeatmap()
    private var selectedIndices: [Int] = []
    private(set) var quality: Float = 0

    // 简化：暴露进度 0~1
    var progress: Float { heatmap.coverage }

    func reset() {
        heatmap = CoverageHeatmap()
        selectedIndices.removeAll()
        quality = 0
    }

    func process(sampleBuffer: CMSampleBuffer, faceMask: CIImage?, blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]?) {
        if let m = faceMask { heatmap.accumulate(mask: m, weight: 1) }
        let blur = scorer.blurScore(sampleBuffer: sampleBuffer)
        let exp  = scorer.exposureScore(sampleBuffer: sampleBuffer)
        let expr = scorer.expressionScore(blendShapes: blendShapes)
        quality = scorer.overall(components: [blur, exp, expr])
    }

    func shouldAcceptFrame() -> Bool {
        return quality > 0.7
    }
}


