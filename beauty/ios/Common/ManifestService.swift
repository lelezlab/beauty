import Foundation
import CryptoKit

struct Manifest: Codable { let version: Int; let effects: [Effect]; let safe_rules_ref: String?; let createdAt: String? }
struct Effect: Codable { let id: String; let ui: String; let unit: String; let map: [String: CodableValue]; let anchors: [String] }
enum CodableValue: Codable {
  case string(String), double(Double), int(Int), bool(Bool), array([CodableValue]), object([String:CodableValue])
  init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let v = try? c.decode(String.self) { self = .string(v); return }
    if let v = try? c.decode(Double.self) { self = .double(v); return }
    if let v = try? c.decode(Int.self) { self = .int(v); return }
    if let v = try? c.decode(Bool.self) { self = .bool(v); return }
    if let v = try? c.decode([CodableValue].self) { self = .array(v); return }
    if let v = try? c.decode([String:CodableValue].self) { self = .object(v); return }
    throw DecodingError.typeMismatch(CodableValue.self, .init(codingPath: decoder.codingPath, debugDescription: "Unsupported"))
  }
  func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self { case .string(let v): try c.encode(v); case .double(let v): try c.encode(v); case .int(let v): try c.encode(v); case .bool(let v): try c.encode(v); case .array(let v): try c.encode(v); case .object(let v): try c.encode(v) }
  }
}

final class ManifestService {
  static let shared = ManifestService()
  // 可选本地 PEM 兜底
  private let fallbackPublicKeyPEM = """
  -----BEGIN PUBLIC KEY-----
  MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEPIftZ2dvvEjSWLXAqNWxz7ukOuvF
  SeUOYcDj7l+4y9x4nYuGYGgfsQA2h6C88ygpi8IIjzbFmS/lAXp4lXuDjg==
  -----END PUBLIC KEY-----
  """

  struct SignedEnvelope: Decodable { let json: Manifest; let signature: String; let payload_b64: String; let created_at: String? }
  enum ManifestError: Error { case invalidURL, badEnvelope, verificationFailed }

  // 优先从 App Bundle 读取自定义 PEM（文件名：manifest_signing_public.pem）
  private func loadLocalPEMFromBundle() -> String? {
    guard let url = Bundle.main.url(forResource: "manifest_signing_public", withExtension: "pem") else { return nil }
    guard let pem = try? String(contentsOf: url), pem.contains("BEGIN PUBLIC KEY") else { return nil }
    return pem
  }

  private func fetchRemotePEM() async -> String? {
    guard let host = URL(string: AppConfig.supabaseBase)?.host,
          let projectRef = host.split(separator: ".").first,
          let url = URL(string: "https://\(projectRef).functions.supabase.co/manifest-sign/pubkey") else { return nil }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
         let pem = obj["public_pem"] as? String, pem.contains("BEGIN PUBLIC KEY") {
        return pem
      }
    } catch { }
    return nil
  }

  func fetchAndVerifyManifest() async throws -> Manifest {
    guard let url = URL(string: AppConfig.manifestURL), !AppConfig.manifestURL.isEmpty else { throw ManifestError.invalidURL }
    let (data, _) = try await URLSession.shared.data(from: url)
    let env = try JSONDecoder().decode(SignedEnvelope.self, from: data)
    guard let payload = Data(base64Encoded: env.payload_b64),
          let sig = Data(base64Encoded: env.signature) else { throw ManifestError.badEnvelope }
    let digest = SHA256.hash(data: payload)

    // 避免在 ?? 的 autoclosure 中使用 await，改为分步骤选择 PEM
    let localPem = loadLocalPEMFromBundle()
    var chosenPem: String?
    if let localPem {
      chosenPem = localPem
    } else {
      chosenPem = await fetchRemotePEM()
    }
    let pem = chosenPem ?? fallbackPublicKeyPEM
    let pub = try P256.Signing.PublicKey(pemRepresentation: pem)
    let signature = try P256.Signing.ECDSASignature(derRepresentation: sig)
    guard pub.isValidSignature(signature, for: digest) else { throw ManifestError.verificationFailed }
    return env.json
  }
}
