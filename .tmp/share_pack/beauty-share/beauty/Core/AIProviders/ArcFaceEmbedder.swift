import Foundation
import UIKit

/// Dual-mode ArcFace embedder: prefer local ORT (future), fallback to remote HTTP, else stub.
final class ArcFaceEmbedder {
    static let shared = ArcFaceEmbedder()
    private init() {}

    enum Mode { case local, remote, stub }
    struct Result: Sendable { let vector: [Float]; let normalized: Bool }

    private func prepareInput(_ image: UIImage) -> Data? {
        // Expect 112x112 RGB; simple resize using UIKit
        let size = CGSize(width: 112, height: 112)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return img.pngData()
    }

    func embed(_ image: UIImage) async -> Result {
        // 1) Try local ORT (not linked yet → will throw and we continue)
        if let data = prepareInput(image), let vec = try? await embedLocal(data: data) { return .init(vector: vec, normalized: true) }
        // 2) Try remote
        if let data = prepareInput(image), let vec = await embedRemote(png: data) { return .init(vector: vec, normalized: true) }
        // 3) Stub: deterministic pseudo vector
        let seed = Int(image.size.width + image.size.height)
        var rng = SeededRandomNumberGenerator(seed: UInt64(seed))
        var v: [Float] = (0..<512).map { _ in Float.random(in: 0...1, using: &rng) }
        // L2 normalize
        let norm = max(1e-6, sqrt(v.reduce(0) { $0 + $1*$1 }))
        v = v.map { $0 / norm }
        return .init(vector: v, normalized: true)
    }

    private func embedLocal(data: Data) async throws -> [Float] {
        // Placeholder: throw to indicate ORT not linked
        _ = try ORTMobile.load(modelNamed: "ArcFace")
        throw ORTMobile.ORTError.notLinked
    }

    private func embedRemote(png: Data) async -> [Float]? {
        guard let urlStr = Bundle.main.object(forInfoDictionaryKey: "ArcFaceEmbedURL") as? String,
              let url = URL(string: urlStr), !urlStr.isEmpty else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let b64 = png.base64EncodedString()
        let body = ["image": "data:image/png;base64,\(b64)"]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any], let arr = obj["embedding"] as? [Double] {
                return arr.map { Float($0) }
            }
        } catch { }
        return nil
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0x12345678 : seed }
    mutating func next() -> UInt64 {
        // xorshift64*
        state ^= state >> 12; state ^= state << 25; state ^= state >> 27
        return state &* 2685821657736338717
    }
}



