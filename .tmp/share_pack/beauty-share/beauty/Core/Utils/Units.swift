import Foundation
import simd

enum Units {
    @inline(__always) static func mmToMeters(_ v: Float) -> Float { v / 1000.0 }
    @inline(__always) static func mmToMeters(_ v: SIMD3<Float>) -> SIMD3<Float> { v / 1000.0 }
}
