import Foundation

public struct EffectControl: Codable, Identifiable {
    public enum ValueType: String, Codable { case float, deg, bool, int }
    public var id: String { key }
    public let key: String
    public let type: ValueType
    public let range: [Double]?
    public let `default`: Double?
    public let unit: String?
    public let map: MapSpec?
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

public enum MapSpec: Codable {
    case linear(k: Double, b: Double)
    case monotoneSpline(knots: [Double], values: [Double])

    private enum CodingKeys: String, CodingKey { case type, k, b, knots, values }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        if type == "linear" {
            let k = try c.decode(Double.self, forKey: .k)
            let b = (try? c.decode(Double.self, forKey: .b)) ?? 0
            self = .linear(k: k, b: b)
            return
        }
        let knots = (try? c.decode([Double].self, forKey: .knots)) ?? []
        let values = (try? c.decode([Double].self, forKey: .values)) ?? []
        self = .monotoneSpline(knots: knots, values: values)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .linear(let k, let b):
            try c.encode("linear", forKey: .type)
            try c.encode(k, forKey: .k)
            try c.encode(b, forKey: .b)
        case .monotoneSpline(let knots, let values):
            try c.encode("monotone-spline", forKey: .type)
            try c.encode(knots, forKey: .knots)
            try c.encode(values, forKey: .values)
        }
    }
}


