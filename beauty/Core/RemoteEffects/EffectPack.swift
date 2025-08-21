import Foundation

public struct EffectControl: Codable, Identifiable {
    public enum ValueType: String, Codable { case float, deg, bool, int }
    public var id: String { key }
    public let key: String
    public let type: ValueType
    public let range: [Double]?
    public let `default`: Double?
}

public struct LandmarkOp: Codable, Identifiable {
    public var id: String { roi + ":" + op }
    public let roi: String
    public let op: String
    public let amountKey: String?
    public let amount: Double?
}

public struct TextureOp: Codable, Identifiable {
    public var id: String { roi + ":" + op }
    public let roi: String
    public let op: String
    public let amount: Double
}

public struct AssetRef: Codable, Identifiable {
    public var id: String { name }
    public let type: String
    public let name: String
    public let sha256: String
}

public struct Legal: Codable { public let region_block: [String]?; public let disclaimer_id: String? }

public struct EffectPack: Codable, Identifiable {
    public let id: String
    public let version: String
    public let min_app_version: String
    public let category: String
    public let display_name: String
    public let controls: [EffectControl]
    public let landmark_ops: [LandmarkOp]
    public let texture_ops: [TextureOp]
    public let assets: [AssetRef]
    public let model_requirements: [String]?
    public let legal: Legal?
    public let telemetry: [String:String]?
}

public struct EffectPackSummary: Codable, Identifiable {
    public let id: String
    public let version: String
    public let url: String
    public let sig: String
    public let rollout: Double
}

public struct EffectManifest: Codable {
    public let public_key_p256: String
    public let effects: [EffectPackSummary]
}


