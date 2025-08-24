import Foundation

enum AuthService {
    // 简化版校验：仅解析 JWT 是否合理，真实环境需服务端验签 Apple 公钥
    static func verifyAppleIdentityToken(_ token: Data) async -> Bool {
        guard let jwt = String(data: token, encoding: .utf8) else { return false }
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return false }
        // 粗检 header/payload 是否可 Base64 解码
        func base64urlToData(_ s: Substring) -> Data? {
            var str = String(s)
            str = str.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
            while str.count % 4 != 0 { str.append("=") }
            return Data(base64Encoded: str)
        }
        guard base64urlToData(parts[0]) != nil, base64urlToData(parts[1]) != nil else { return false }
        // 若配置了后端端点，则尝试校验
        if let endpoint = UserDefaults.standard.string(forKey: "auth_endpoint"), !endpoint.isEmpty,
           let url = URL(string: endpoint) {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: String] = ["provider": "apple", "token": jwt]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                    // 允许 2xx，进一步可解析 { ok: true }
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let ok = json["ok"] as? Bool {
                        return ok
                    }
                    return true
                }
                return false
            } catch {
                return false
            }
        }
        // 无后端时，保留本地初检通过
        return true
    }
}

extension AuthService {
    static func sendOTP(to: String, channel: String) async -> Bool {
        // Use configured endpoint if provided
        if let endpoint = UserDefaults.standard.string(forKey: "otp_send_endpoint"),
           let url = URL(string: endpoint), !endpoint.isEmpty {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["to": to, "channel": channel]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            do {
                let (_, resp) = try await URLSession.shared.data(for: req)
                if let http = resp as? HTTPURLResponse { return (200..<300).contains(http.statusCode) }
            } catch { return false }
            return false
        }
        // Fallback local simulation
        try? await Task.sleep(nanoseconds: 500_000_000)
        return true
    }

    static func verifyOTP(to: String, code: String, channel: String) async -> Bool {
        if let endpoint = UserDefaults.standard.string(forKey: "otp_verify_endpoint"),
           let url = URL(string: endpoint), !endpoint.isEmpty {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = ["to": to, "code": code, "channel": channel]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                if let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let ok = json["ok"] as? Bool { return ok }
                    return true
                }
                return false
            } catch { return false }
        }
        // Local fallback: accept any 4+ digits
        return code.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
    }
}


