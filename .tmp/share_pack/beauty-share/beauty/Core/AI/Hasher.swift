import Foundation
import CryptoKit

enum Hasher {
    static func verifySHA256(filePath: String, hex: String) throws -> Bool {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        return digest.lowercased() == hex.lowercased()
    }
}



