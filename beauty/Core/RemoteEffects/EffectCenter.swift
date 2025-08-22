import Foundation

final class EffectCenter: ObservableObject {
    static let shared = EffectCenter()

    @Published private(set) var activeEffects: [EffectPack] = []
    @Published private(set) var manifest: EffectManifest?

    private let fileManager = FileManager.default
    private var baseURL: URL { fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Effects", isDirectory: true) }

    func fetchManifest(from url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        let mf = try JSONDecoder().decode(EffectManifest.self, from: data)
        manifest = mf
    }

    func syncEffects(deviceId: String, appVersion: String, regionCode: String) async {
        guard let mf = manifest else { return }
        for s in mf.effects {
            let hit = rolloutHit(deviceId: deviceId, rollout: s.rollout)
            // 记录一次遥测（配置/灰度），区分命中与否，并附加 effectId
            let change = BTConfigChange(source: hit ? "EffectCenter.hit" : "EffectCenter.miss",
                                        keys: ["rollout": s.rollout],
                                        labels: ["effectId": s.id, "version": s.version])
            BeautyTelemetryService.shared.recordConfigChange(change)
            guard hit else { continue }
            do { try await downloadIfNeeded(summary: s, manifest: mf, appVersion: appVersion, regionCode: regionCode) } catch {
                // TODO: log telemetry
            }
        }
        loadLocalIfAvailable()
    }

    private func downloadIfNeeded(summary: EffectPackSummary, manifest: EffectManifest, appVersion: String, regionCode: String) async throws {
        if let local = localPack(id: summary.id, version: summary.version) { activeEffects.append(local); return }
        let (data, _) = try await URLSession.shared.data(from: URL(string: summary.url)!)
        guard SignatureVerifier.verify(manifest: manifest, data: data, base64Signature: summary.sig) else { return }
        let pack = try JSONDecoder().decode(EffectPack.self, from: data)
        guard Version(appVersion) >= Version(pack.min_app_version) else { return }
        if let block = pack.legal?.region_block, block.contains(regionCode.uppercased()) { return }
        try save(pack: pack, rawJSON: data)
        activeEffects.append(pack)
    }

    private func save(pack: EffectPack, rawJSON: Data) throws {
        let dir = baseURL.appendingPathComponent(pack.id).appendingPathComponent(pack.version)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        try rawJSON.write(to: dir.appendingPathComponent("pack.json"))
        // assets 校验与缓存略（示意）
        try setCurrent(pack: pack)
    }

    private func setCurrent(pack: EffectPack) throws {
        let current = baseURL.appendingPathComponent(pack.id).appendingPathComponent("current")
        try? fileManager.removeItem(at: current)
        let target = baseURL.appendingPathComponent(pack.id).appendingPathComponent(pack.version)
        try fileManager.createSymbolicLink(at: current, withDestinationURL: target)
    }

    private func localPack(id: String, version: String) -> EffectPack? {
        let p = baseURL.appendingPathComponent(id).appendingPathComponent(version).appendingPathComponent("pack.json")
        guard let data = try? Data(contentsOf: p) else { return nil }
        return try? JSONDecoder().decode(EffectPack.self, from: data)
    }

    func loadLocalIfAvailable() {
        var loaded: [EffectPack] = []
        guard let dirs = try? fileManager.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil) else { return }
        for idDir in dirs {
            let current = idDir.appendingPathComponent("current/pack.json")
            if let data = try? Data(contentsOf: current), let pack = try? JSONDecoder().decode(EffectPack.self, from: data) { loaded.append(pack) }
        }
        // 离线兜底：加载内置本地效果包
        if let bundle = Bundle.main.path(forResource: "Effects/local/rhinoplasty_2025Q3_01", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: bundle)),
           let pack = try? JSONDecoder().decode(EffectPack.self, from: data) { loaded.append(pack) }
        if let bundle = Bundle.main.path(forResource: "Effects/local/jawline_2025Q3_01", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: bundle)),
           let pack = try? JSONDecoder().decode(EffectPack.self, from: data) { loaded.append(pack) }
        activeEffects = loaded
    }

    // MARK: - Rollout & Version helper
    private func rolloutHit(deviceId: String, rollout: Double) -> Bool {
        guard rollout < 1 else { return true }
        // 使用稳定哈希（SHA256）确保跨进程一致
        let hex = SignatureHelper.sha256Hex(Data(deviceId.utf8))
        let tail = hex.suffix(8)
        let val = UInt32(tail, radix: 16) ?? 0
        let p = Double(val % 10000) / 10000.0
        return p < rollout
    }
}

struct Version: Comparable { let comps: [Int]; init(_ s: String){ comps = s.split(separator: ".").map{ Int($0) ?? 0 } }
    static func < (l: Version, r: Version) -> Bool {
        for i in 0..<max(l.comps.count, r.comps.count){ let a = i<l.comps.count ? l.comps[i]:0; let b=i<r.comps.count ? r.comps[i]:0; if a != b { return a < b } }
        return false
    }
}


