import Foundation
import UIKit

struct CelebEntry: Codable, Identifiable { let id: String; let name: String; let imagePath: String }
struct TopMatch: Identifiable { let id: String; let name: String; let score: Double; let thumb: UIImage? }

final class EmbedIndexBuilder {
    private let model: EmbeddingModel
    init(model: EmbeddingModel) { self.model = model }

    func build(from folder: URL) -> ([CelebEntry], [[Float]]) {
        // 期望结构：images/*.jpg, names.csv (id,name,filename)
        let imagesDir = folder.appendingPathComponent("images", isDirectory: true)
        let csv = folder.appendingPathComponent("names.csv")
        var entries: [CelebEntry] = []
        if let text = try? String(contentsOf: csv), !text.isEmpty {
            for line in text.split(separator: "\n").dropFirst() {
                let parts = line.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
                if parts.count >= 3 {
                    let e = CelebEntry(id: parts[0], name: parts[1], imagePath: imagesDir.appendingPathComponent(parts[2]).path)
                    entries.append(e)
                }
            }
        }
        var vectors: [[Float]] = []
        for e in entries {
            if let img = UIImage(contentsOfFile: e.imagePath), let v = model.embed(img) { vectors.append(v) } else { vectors.append([]) }
        }
        return (entries, vectors)
    }
}

enum EmbedSearch {
    static func cosine(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Double = 0, na: Double = 0, nb: Double = 0
        for i in 0..<a.count { dot += Double(a[i]*b[i]); na += Double(a[i]*a[i]); nb += Double(b[i]*b[i]) }
        let denom = (sqrt(na)*sqrt(nb))
        return denom > 1e-9 ? max(0, min(1, dot/denom)) : 0
    }
}

final class CelebMatcher {
    private let entries: [CelebEntry]
    private let vectors: [[Float]]
    private let model: EmbeddingModel
    init(entries: [CelebEntry], vectors: [[Float]], model: EmbeddingModel) { self.entries = entries; self.vectors = vectors; self.model = model }

    func topK(for image: UIImage, k: Int = 3) -> [TopMatch] {
        guard let q = model.embed(image) else { return [] }
        var scores: [(Int, Double)] = []
        for (i, v) in vectors.enumerated() { if !v.isEmpty { scores.append((i, EmbedSearch.cosine(q, v))) } }
        let sorted = scores.sorted { $0.1 > $1.1 }.prefix(k)
        return sorted.map { (idx, s) in
            let e = entries[idx]
            return TopMatch(id: e.id, name: e.name, score: s, thumb: UIImage(contentsOfFile: e.imagePath))
        }
    }
}


