import Foundation

struct Anchors3D: Decodable { let indices: [String: Int] }

enum Anchors3DParser {
    static func load(url: URL) -> Anchors3D? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Anchors3D.self, from: data)
    }
}


