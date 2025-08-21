import XCTest
@testable import beauty
import CoreGraphics

final class AestheticsMetricsTests: XCTestCase {
    func testFiveEyesNormalization() {
        let landmarks = FacialLandmarksResult(
            boundingBox: .zero, roll: 0, yaw: 0, pitch: 0,
            points: [
                "faceContour": [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)],
                "leftEye": [CGPoint(x: 30, y: 40), CGPoint(x: 40, y: 40)],
                "rightEye": [CGPoint(x: 60, y: 40), CGPoint(x: 70, y: 40)],
                "nose": [CGPoint(x: 50, y: 60)],
                "outerLips": [CGPoint(x: 45, y: 80), CGPoint(x: 55, y: 80)]
            ]
        )
        let m = MetricsCalculator.compute(from: landmarks, imageSize: .init(width: 100, height: 100))
        XCTAssertGreaterThan(m.fiveEyesRatio, 1.0)
    }
}


