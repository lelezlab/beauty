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
    static func assess(landmarks: [String: CGPoint]) -> BeautyAssessment {
        // 占位：返回空，后续接入真实计算并映射到建议参数
        return BeautyAssessment(items: [], summaryScore: 0)
    }
}


