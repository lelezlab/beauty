import CoreGraphics

public struct FivePoint {
    public var leftEye: CGPoint
    public var rightEye: CGPoint
    public var nose: CGPoint
    public var mouthLeft: CGPoint
    public var mouthRight: CGPoint
    public init(leftEye: CGPoint, rightEye: CGPoint, nose: CGPoint, mouthLeft: CGPoint, mouthRight: CGPoint) {
        self.leftEye = leftEye; self.rightEye = rightEye; self.nose = nose; self.mouthLeft = mouthLeft; self.mouthRight = mouthRight
    }
}

public enum AlignTemplate {
    // ArcFace 112×112 模板
    public static let arcface112: [CGPoint] = [
        CGPoint(x: 38.2946, y: 51.6963),
        CGPoint(x: 73.5318, y: 51.5014),
        CGPoint(x: 56.0252, y: 71.7366),
        CGPoint(x: 41.5493, y: 92.3655),
        CGPoint(x: 70.7299, y: 92.2041)
    ]
}


