import Foundation
import UIKit

struct ParsingResult: Sendable { let maskPNG: Data; let classes: [String] }

enum FaceParsingClient {
    static func parse(_ image: UIImage) async -> ParsingResult? {
        guard let urlStr = Bundle.main.object(forInfoDictionaryKey: "FaceParsingURL") as? String,
              let url = URL(string: urlStr), !urlStr.isEmpty,
              let png = image.pngData() else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["image": "data:image/png;base64,\(png.base64EncodedString())"]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let b64 = obj["mask_png"] as? String, let mdata = Data(base64Encoded: b64) {
                let classes = obj["classes"] as? [String] ?? []
                return ParsingResult(maskPNG: mdata, classes: classes)
            }
        } catch { }
        return nil
    }
}



