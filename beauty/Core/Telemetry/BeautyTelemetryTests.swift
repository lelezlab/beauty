import XCTest
@testable import beauty
import CoreGraphics

final class BeautyTelemetryCoreTests: XCTestCase {
    func testLandmarkNormalization() {
        let pts: [String: [CGPoint]] = [
            "leftEye": [CGPoint(x: 10, y: 10), CGPoint(x: 12, y: 10)],
            "rightEye": [CGPoint(x: 30, y: 10), CGPoint(x: 32, y: 10)],
            "nose": [CGPoint(x: 20, y: 20)]
        ]
        let res = LandmarkNormalizer.normalize(points: pts)
        XCTAssertNotNil(res)
        XCTAssertGreaterThan(res!.ipd, 0)
    }

    func testLaplaceNoise() {
        var zero = 0.0
        for _ in 0..<1000 { zero += Laplace.sample(scale: 1.0) }
        zero /= 1000.0
        XCTAssert(abs(zero) < 0.2) // 粗略检验均值不偏移过大
    }
}


