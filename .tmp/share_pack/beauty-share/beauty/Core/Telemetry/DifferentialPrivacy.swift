import Foundation

enum DifferentialPrivacy {
    static func laplace(_ x: Double, epsilon: Double) -> Double {
        let scale = 1.0 / max(0.5, epsilon)
        let u = Double.random(in: -0.5...0.5)
        return x - scale * sgn(u) * log(1 - 2 * abs(u))
    }
    private static func sgn(_ x: Double) -> Double { x >= 0 ? 1 : -1 }
}


