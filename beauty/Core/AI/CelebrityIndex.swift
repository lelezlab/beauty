import Foundation
import UIKit

struct CelebrityItem: Decodable { let id: String; let name: String; let gender: String?; let emb: [Float]; let image: String? }

final class CelebrityIndex {
    static let shared = CelebrityIndex()
    private init() {}
    private(set) var items: [CelebrityItem] = []

    func load() {
        if let url = Bundle.main.url(forResource: "CelebIndex/celeb_index", withExtension: "jsonl", subdirectory: "Resources") ??
                     Bundle.main.url(forResource: "CelebIndex/celeb_index", withExtension: "jsonl") {
            if let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) {
                var arr: [CelebrityItem] = []
                for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
                    if let obj = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any] {
                        let id = obj["id"] as? String ?? ""
                        let name = obj["name"] as? String ?? id
                        let gender = obj["gender"] as? String
                        let emb = (obj["emb"] as? [Double])?.map { Float($0) } ?? []
                        let image = obj["image"] as? String
                        arr.append(CelebrityItem(id: id, name: name, gender: gender, emb: emb, image: image))
                    }
                }
                self.items = arr
            }
        }
    }

    func topK(for vector: [Float], k: Int = 5) -> [(CelebrityItem, Float)] {
        guard !items.isEmpty, !vector.isEmpty else { return [] }
        let vn = l2norm(vector)
        var scored: [(CelebrityItem, Float)] = []
        for it in items {
            if it.emb.count != vector.count { continue }
            let s = dot(vn, l2norm(it.emb))
            scored.append((it, s))
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(k).map { $0 }
    }

    private func dot(_ a: [Float], _ b: [Float]) -> Float {
        var s: Float = 0
        for i in 0..<min(a.count,b.count) { s += a[i]*b[i] }
        return s
    }
    private func l2norm(_ v: [Float]) -> [Float] {
        let n = max(1e-6, sqrt(v.reduce(0) { $0 + $1*$1 }))
        return v.map { $0 / n }
    }
}


