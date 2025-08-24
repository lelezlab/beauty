import Foundation
import UIKit

enum DepthClient {
    static func infer(_ image: UIImage) async -> Data? {
        guard let urlStr = Bundle.main.object(forInfoDictionaryKey: "MiDaSDepthURL") as? String,
              let url = URL(string: urlStr), !urlStr.isEmpty,
              let png = image.pngData() else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["image": "data:image/png;base64,\(png.base64EncodedString())"]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any], let b64 = obj["depth_png"] as? String {
                return Data(base64Encoded: b64)
            }
        } catch { }
        return nil
    }
}



