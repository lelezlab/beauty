import Foundation

final class SupabaseTelemetryUploader: TelemetryUploader {
    enum UploadError: Error { case configMissing, badResponse }

    private let baseURL: URL
    private let anonKey: String
    private let queue = FileTelemetryQueue()

    init?(url: URL? = SupabaseConfig.url ?? URL(string: SupabaseEnv.url), anonKey: String? = SupabaseConfig.anonKey ?? (SupabaseEnv.anonKey.isEmpty ? nil : SupabaseEnv.anonKey)) {
        guard let url = url, let anonKey = anonKey else { return nil }
        self.baseURL = url
        self.anonKey = anonKey
    }

    func enqueue(_ batch: [BTEvent]) throws {
        queue.append(batch)
    }

    func flush() async {
        let events = queue.readAll()
        guard !events.isEmpty else { return }
        // Insert sessions first (unique by sessionId)
        let sessionsRows = sessionsPayload(from: events)
        if !sessionsRows.isEmpty { _ = try? await bulkInsert(table: "sessions", rows: sessionsRows) }
        // Partition by kind → table
        let captures = events.filter{ $0.kind == .capture || $0.kind == .geometry }.compactMap { captureRow($0) }
        let effects = events.filter{ $0.kind == .effect }.compactMap { effectRow($0) }
        let ratings = events.filter{ $0.kind == .rating }.compactMap { ratingRow($0) }
        let experts = events.filter{ $0.kind == .expert }.compactMap { expertRow($0) }
        // Batch size 100
        await withTaskGroup(of: Void.self) { group in
            for chunk in Self.chunk(captures, size: 100) { group.addTask { _ = try? await self.bulkInsert(table: "captures", rows: chunk) } }
            for chunk in Self.chunk(effects, size: 100) { group.addTask { _ = try? await self.bulkInsert(table: "effects", rows: chunk) } }
            for chunk in Self.chunk(ratings, size: 100) { group.addTask { _ = try? await self.bulkInsert(table: "ratings", rows: chunk) } }
            for chunk in Self.chunk(experts, size: 100) { group.addTask { _ = try? await self.bulkInsert(table: "experts", rows: chunk) } }
        }
        // On success (best-effort), clear queue
        queue.writeAll([])
    }

    private func sessionsPayload(from events: [BTEvent]) -> [[String: Any]] {
        var seen = Set<String>()
        var rows: [[String: Any]] = []
        for e in events {
            let id = e.session.sessionId
            if seen.contains(id) { continue }
            seen.insert(id)
            rows.append([
                "id": id,
                "device_hash": e.session.deviceHash,
                "os": e.session.os,
                "region": e.session.locale,
            ])
        }
        return rows
    }
    private func captureRow(_ e: BTEvent) -> [String: Any]? {
        switch e.kind {
        case .capture:
            return [
                "session_id": e.session.sessionId,
                "view": "front",
                "qc_json": encodableToJSONObject(e.captureQC),
                "meta_json": NSNull(),
                "saved_local_path_hash": NSNull()
            ]
        case .geometry:
            return [
                "session_id": e.session.sessionId,
                "view": "front",
                "qc_json": NSNull(),
                "meta_json": [
                    "geom": encodableToJSONObject(e.geom),
                    "metrics": encodableToJSONObject(e.metrics)
                ],
                "saved_local_path_hash": NSNull()
            ]
        default: return nil
        }
    }
    private func effectRow(_ e: BTEvent) -> [String: Any]? {
        guard let eff = e.effect else { return nil }
        return [
            "session_id": e.session.sessionId,
            "effect_id": eff.effectId,
            "version": eff.version,
            "params_json": eff.params,
            "confidence": eff.confidenceScore as Any? ?? NSNull()
        ]
    }
    private func ratingRow(_ e: BTEvent) -> [String: Any]? {
        guard let r = e.rating else { return nil }
        return [
            "session_id": e.session.sessionId,
            "realism": r.realism as Any? ?? NSNull(),
            "satisfaction": r.satisfaction as Any? ?? NSNull(),
            "regions": r.regions as Any? ?? NSNull()
        ]
    }
    private func expertRow(_ e: BTEvent) -> [String: Any]? {
        guard let ex = e.expert else { return nil }
        return [
            "session_id": e.session.sessionId,
            "clinic_id": "local",
            "advice_json": encodableToJSONObject(ex)
        ]
    }

    private func encodableToJSONObject<T: Encodable>(_ obj: T?) -> Any {
        guard let obj = obj else { return NSNull() }
        if let data = try? JSONEncoder().encode(obj),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            return json
        }
        return NSNull()
    }

    private func bulkInsert(table: String, rows: [[String: Any]]) async throws -> Bool {
        guard !rows.isEmpty else { return true }
        var req = URLRequest(url: baseURL.appendingPathComponent("/rest/v1/\(table)"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("\(anonKey)", forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try JSONSerialization.data(withJSONObject: rows, options: [])
        var attempt = 0
        while attempt < 5 {
            do {
                let (_, resp) = try await URLSession.shared.data(for: req)
                if let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode { return true }
            } catch {}
            attempt += 1
            let backoff = min(pow(2.0, Double(attempt)), 30.0)
            try? await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
        }
        return false
    }

    private static func chunk<T>(_ array: [T], size: Int) -> [[T]] {
        guard size > 0 else { return [array] }
        var res: [[T]] = []
        var i = 0
        while i < array.count {
            let j = min(i + size, array.count)
            res.append(Array(array[i..<j]))
            i = j
        }
        return res
    }
}


