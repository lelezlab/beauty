import Foundation

public struct RuleHit: Codable {
    public let id: String
    public let title: String
    public let message: String
    public let severity: String
    public let citations: [String]
    public let value: Double?
    public let refRange: String?
}

public final class RulesEngine {
    public struct Context {
        public let gender: String?
        public let age: Int?
        public let ethnicity: String?
        public init(gender: String?, age: Int?, ethnicity: String?) {
            self.gender = gender; self.age = age; self.ethnicity = ethnicity
        }
    }

    private struct RuleDef: Decodable {
        let id, title, metric, severity: String
        let range: [String: [String: Double]]?
        let message: String
        let citations: [String]
    }

    private var rules: [RuleDef] = []
    private var refs: [String: String] = [:]
    public init(rulesURL: URL, refsURL: URL) throws {
        let yaml = try String(contentsOf: rulesURL, encoding: .utf8)
        self.rules = try YAMLDecoder().decode([RuleDef].self, from: yaml)
        let data = try Data(contentsOf: refsURL)
        self.refs = try JSONDecoder().decode([String:String].self, from: data)
    }

    public func evaluate(measures: FacialMeasures, ctx: Context) -> [RuleHit] {
        var hits: [RuleHit] = []
        for r in rules {
            let val = value(for: r.metric, measures: measures)
            guard let v = val else { continue }
            let seg = (ctx.gender ?? "ALL")
            let rr = r.range?[seg] ?? r.range?["ALL"]
            var violated = false
            var rrStr: String? = nil
            if let min = rr?["min"], let max = rr?["max"] {
                rrStr = "[\(min) , \(max)]"
                violated = (v < min || v > max)
            }
            if violated {
                hits.append(.init(
                    id: r.id,
                    title: r.title,
                    message: r.message,
                    severity: r.severity,
                    citations: r.citations.compactMap{ refs[$0] ?? $0 },
                    value: Double(v),
                    refRange: rrStr
                ))
            }
        }
        return hits
    }

    private func value(for key: String, measures: FacialMeasures) -> Float? {
        switch key {
        case "nasolabial_angle": return measures.nasolabialAngleDeg
        case "mentocervical_angle": return measures.mentocervicalAngleDeg
        case "intercanthal_to_eye_width": return measures.intercanthalToEyeWidth
        default: return nil
        }
    }
}

struct YAMLDecoder {
    func decode<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T {
        let data = Data(yaml.utf8)
        return try JSONDecoder().decode(T.self, from: data)
    }
}


