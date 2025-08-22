import Foundation
import UIKit
#if canImport(Vision)
import Vision
#endif

struct TopMatch: Identifiable { let id: String; let name: String; let score: Float; let thumb: UIImage? }

enum CelebMatch {
    static let indexDir: URL = {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("celeb_index", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    static func importGallery(zipURL: URL) async throws {
        // 简化实现：若传入的是已解压的目录则直接使用；若是 .zip 则记录路径提示用户在 Mac 端解压
        #if canImport(Foundation)
        let dest = indexDir.appendingPathComponent("gallery", isDirectory: true)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
        if zipURL.hasDirectoryPath {
            _ = try? FileManager.default.copyItem(at: zipURL, to: dest)
        } else if zipURL.pathExtension.lowercased() == "zip" {
            let note = "Please extract the ZIP on desktop and re-import the extracted folder. Path: \(zipURL.path)"
            try? note.data(using: .utf8)?.write(to: dest.appendingPathComponent("IMPORT_NOTE.txt"))
        }
        // 读取 names.csv
        let namesURL = dest.appendingPathComponent("names.csv")
        let text = (try? String(contentsOf: namesURL)) ?? ""
        var entries: [CelebEntry] = []
        let lines = text.split(separator: "\n").map(String.init)
        if lines.count > 1 {
            let header = lines[0].split(separator: ",").map(String.init)
            for line in lines.dropFirst() {
                let vals = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
                let dict = Dictionary(uniqueKeysWithValues: zip(header, vals))
                if let fid = dict["id"], let name = dict["name"] {
                    let path = dest.appendingPathComponent("images").appendingPathComponent(fid + ".jpg").path
                    entries.append(.init(id: fid, name: name, imagePath: path))
                }
            }
        }
        // 构建向量
        let model: AnyFaceEmbedder = (FaceEmbedder() ?? nil) as? AnyFaceEmbedder ?? StubFaceEmbedder()
        let builder = EmbedIndexBuilder(model: StubEmbeddingModel())
        let (es, vecs) = builder.build(from: dest)
        // 持久化（简化为 JSON）
        let metaURL = indexDir.appendingPathComponent("entries.json")
        let vecURL = indexDir.appendingPathComponent("vectors.json")
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted]
        try? enc.encode(es).write(to: metaURL)
        try? JSONSerialization.data(withJSONObject: vecs.map { $0.map { Double($0) } }).write(to: vecURL)
        #endif
    }

    static func match(image: UIImage, topK: Int = 3) throws -> [TopMatch] {
        // 对齐（若可用）
        var aligned: UIImage = image
        #if canImport(Vision)
        if let cg = image.cgImage {
            let req = VNDetectFaceLandmarksRequest()
            let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
            try? handler.perform([req])
            if let obs = (req.results as? [VNFaceObservation])?.first,
               let p5 = VisionLandmarksAdapter.fivePoint(from: obs, in: image.size),
               let chip = FaceAlignment.align(image, landmarks: p5) { aligned = chip }
        }
        #endif
        // 载入索引
        let metaURL = indexDir.appendingPathComponent("entries.json")
        let vecURL = indexDir.appendingPathComponent("vectors.json")
        guard let dataE = try? Data(contentsOf: metaURL), let entries = try? JSONDecoder().decode([CelebEntry].self, from: dataE), let vecData = try? Data(contentsOf: vecURL), let arr = try? JSONSerialization.jsonObject(with: vecData) as? [[Double]] else { return [] }
        let vectors: [[Float]] = arr.map { $0.map { Float($0) } }
        // 选择嵌入器
        let embedder: AnyFaceEmbedder = (FaceEmbedder() ?? nil) as AnyFaceEmbedder? ?? StubFaceEmbedder()
        let q = (try? embedder.embed(aligned)) ?? []
        var scores: [(Int, Double)] = []
        for (i, v) in vectors.enumerated() { if !v.isEmpty { scores.append((i, EmbedSearch.cosine(q, v))) } }
        return scores.sorted { $0.1 > $1.1 }.prefix(topK).map { (idx, s) in
            let e = entries[idx]
            return TopMatch(id: e.id, name: e.name, score: Float(s), thumb: UIImage(contentsOfFile: e.imagePath))
        }
    }
}


