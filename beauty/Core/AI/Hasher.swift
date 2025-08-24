import Foundation
import CryptoKit

enum Hasher {
    static func verifySHA256(filePath: String, hex: String) throws -> Bool {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return digest.lowercased() == hex.lowercased()
    }
    static func sha256Hex(filePath: String) -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}



