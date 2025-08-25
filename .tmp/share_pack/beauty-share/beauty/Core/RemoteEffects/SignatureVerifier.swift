import Foundation
import CryptoKit

enum SignatureVerifier {
    static func verify(manifest: EffectManifest, data: Data, base64Signature: String) -> Bool {
        guard let sigData = Data(base64Encoded: base64Signature),
              let pubData = Data(base64Encoded: manifest.public_key_p256) else { return false }
        do {
            let pubKey = try P256.Signing.PublicKey(x963Representation: pubData)
            let signature = try P256.Signing.ECDSASignature(derRepresentation: sigData)
            return pubKey.isValidSignature(signature, for: SHA256.hash(data: data))
        } catch { return false }
    }

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}


