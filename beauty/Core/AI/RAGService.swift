import Foundation

struct RAGAnswer: Sendable { let text: String }

enum RAGService {
    struct Chunk { let id: String; let text: String }

    static func loadChunks() -> [Chunk] {
        // Try Resources/Knowledge/kb_chunks.jsonl, else docs/*.md as fallback
        if let url = Bundle.main.url(forResource: "Knowledge/kb_chunks", withExtension: "jsonl", subdirectory: "Resources") {
            if let data = try? Data(contentsOf: url), let content = String(data: data, encoding: .utf8) {
                return content.split(separator: "\n").compactMap { line in
                    guard let obj = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String:Any] else { return nil }
                    let id = (obj["id"] as? String) ?? UUID().uuidString
                    let text = (obj["text"] as? String) ?? ""
                    return Chunk(id: id, text: text)
                }
            }
        }
        // Fallback: collect docs markdown as chunks
        var chunks: [Chunk] = []
        if let docsURL = Bundle.main.url(forResource: "docs", withExtension: nil) {
            if let paths = try? FileManager.default.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil) {
                for p in paths where p.pathExtension.lowercased() == "md" {
                    if let s = try? String(contentsOf: p) { chunks.append(Chunk(id: p.lastPathComponent, text: s)) }
                }
            }
        }
        return chunks
    }

    static func answer(for metrics: AestheticsMetrics?, suggestions: [Suggestion]) async -> RAGAnswer {
        let chunks = loadChunks()
        let question = buildQuery(metrics: metrics, suggestions: suggestions)
        let scored = score(question: question, chunks: chunks).prefix(5)
        let summary = summarize(question: question, contexts: scored.map { $0.0.text })
        BeautyTelemetryService.shared.recordAction(BTActionRecord(withPDF: false, shared: false, exported: false))
        return RAGAnswer(text: summary)
    }

    private static func buildQuery(metrics: AestheticsMetrics?, suggestions: [Suggestion]) -> String {
        var q: [String] = ["patient: aesthetic assessment"]
        if let m = metrics {
            q.append(String(format: "threeZones=%.2f fiveEyes=%.2f nasolabial=%.1f chinProj=%.2f whRatio=%.2f", m.threeFacialZonesRatio, m.fiveEyesRatio, m.nasolabialAngleDegrees, m.chinProjectionRatio, m.faceWidthToHeight))
        }
        if !suggestions.isEmpty { q.append("suggestions:" + suggestions.map { $0.title }.joined(separator: ",")) }
        return q.joined(separator: " ")
    }

    // Simple lexical scoring (BM25-lite)
    private static func score(question: String, chunks: [Chunk]) -> [(Chunk, Double)] {
        let qTokens = tokens(question)
        var results: [(Chunk, Double)] = []
        for c in chunks {
            let t = tokens(c.text)
            var s = 0.0
            for tok in qTokens { if t.contains(tok) { s += 1.0 } }
            if s > 0 { results.append((c, s / Double(t.count + 1))) }
        }
        return results.sorted { $0.1 > $1.1 }
    }

    private static func summarize(question: String, contexts: [String]) -> String {
        let intro = "根据测量指标与知识库，给出术式说明与预算区间：\n\n"
        let body = contexts.prefix(3).joined(separator: "\n---\n")
        let tail = "\n\n注意：本建议仅作审美与教育用途，不构成医疗意见。"
        return intro + body + tail
    }

    private static func tokens(_ s: String) -> Set<String> {
        let seps = CharacterSet.alphanumerics.inverted
        return Set(s.lowercased().components(separatedBy: seps).filter { $0.count > 1 })
    }
}


