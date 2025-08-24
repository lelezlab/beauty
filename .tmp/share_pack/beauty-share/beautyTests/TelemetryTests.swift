import XCTest
@testable import beauty
import CoreGraphics

final class TelemetryTests: XCTestCase {
    func testLaplaceNoiseMean() {
        var s = 0.0
        for _ in 0..<10000 {
            s += Laplace.sample(scale: 0.5)
        }
        let mean = s/10000.0
        XCTAssert(abs(mean) < 0.15)
    }

    func testNormalize468() {
        let left = [CGPoint(x: 10, y: 10), CGPoint(x: 12, y: 10)]
        let right = [CGPoint(x: 30, y: 10), CGPoint(x: 32, y: 10)]
        let pts = [CGPoint(x: 20, y: 10)]
        let res = LandmarksNormalizer.normalize468(points: pts, leftEye: left, rightEye: right)
        XCTAssertNotNil(res)
        if let (ipd, norm) = res {
            XCTAssert(ipd > 15 && ipd < 25)
            XCTAssertEqual(norm.count, 1)
        }
    }

    func testQueueSerializeDeserialize() throws {
        let q = FileTelemetryQueue(filename: "test.queue.json")
        let env = BTSessionEnvelope(sessionId: "s1", timestamp: Date(), device: "iPhone", os: "iOS", locale: "zh_CN", deviceHash: "abc")
        let e = BTEvent(kind: .action, session: env, captureQC: nil, geom: nil, metrics: nil, effect: nil, rating: nil, action: BTActionRecord(withPDF: false, shared: false, exported: false), expert: nil, procedure: nil, knowledgeKey: nil, knowledgeAction: nil, knowledgeDurationSec: nil, knowledgeScrollDepth: nil, config: nil, prefill: nil)
        q.writeAll([e])
        let out = q.readAll()
        XCTAssertEqual(out.count, 1)
        // cleanup not strictly needed
    }
}


