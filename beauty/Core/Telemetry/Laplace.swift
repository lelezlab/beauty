import Foundation

enum Laplace {
    static func sample(scale b: Double) -> Double {
        // Inverse CDF sampling: U∼Uniform(-0.5,0.5), X = -b * sgn(U) * ln(1 - 2|U|)
        let u = Double.random(in: -0.5...0.5)
        let sign = u >= 0 ? 1.0 : -1.0
        return -b * sign * log(1 - 2 * abs(u))
    }
}


