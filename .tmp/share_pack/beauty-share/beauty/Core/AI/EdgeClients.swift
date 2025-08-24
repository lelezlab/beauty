import Foundation

struct EdgeClient {
    static func postJSON(url: URL, body: [String: Any], timeout: TimeInterval = 2.5, retries: Int = 2) async throws -> Data {
        var attempt = 0
        var delay: TimeInterval = 0.4
        var lastErr: Error?
        while attempt <= retries {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = timeout
            req.addValue(DeviceHash.anon(), forHTTPHeaderField: "x-device-hash")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            do {
                let (data, _) = try await URLSession.shared.data(for: req)
                return data
            } catch {
                lastErr = error
                if attempt == retries { break }
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay *= 2
                attempt += 1
            }
        }
        throw lastErr ?? URLError(.timedOut)
    }
}

enum DeviceHash {
    static func anon() -> String {
        let key = "device_hash_v1"
        if let v = UserDefaults.standard.string(forKey: key) { return v }
        let v = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        UserDefaults.standard.set(v, forKey: key)
        return v
    }
}



