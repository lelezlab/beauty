import Foundation
import CoreGraphics
import UIKit
import CryptoKit

// MARK: - Data Models

public struct BTCaptureQC: Codable {
    public let blurScore: Double
    public let exposureMean: Double
    public let faceCoverage: Double
    public let yaw: Double?
    public let pitch: Double?
    public let roll: Double?
    public let focalEq: Double?
    public let distanceBucket: Int?
    public let aeLocked: Bool?
    public let awbLocked: Bool?
}

public struct BTGeomPayload: Codable {
    public let ipd: Double
    public let points: [String: [[Double]]]
}

public struct BTMetricsPayload: Codable {
    public let threeZones: Double?
    public let fiveEyes: Double?
    public let nasolabialDeg: Double?
    public let chinProjection: Double?
    public let faceWH: Double?
}

public struct BTEffectRecord: Codable {
    public let effectId: String
    public let version: String
    public let params: [String: Double]
    public let confidenceScore: Double?
}

public struct BTRatingRecord: Codable {
    public let realism: Int?
    public let satisfaction: Int?
    public let regions: [String]?
}

public struct BTSessionEnvelope: Codable {
    public let sessionId: String
    public let timestamp: Date
    public let device: String
    public let os: String
    public let locale: String
    public let deviceHash: String
}

public struct BTActionRecord: Codable { public let withPDF: Bool; public let shared: Bool; public let exported: Bool }
public struct BTExpertAdvice: Codable { public let effectId: String; public let adviceJSON: [String: [Double]]?; public let contraindications: [String]? }

public struct BTEvent: Codable {
    public enum Kind: String, Codable { case capture, geometry, metrics, effect, rating, action, expert }
    public let kind: Kind
    public let session: BTSessionEnvelope
    public let captureQC: BTCaptureQC?
    public let geom: BTGeomPayload?
    public let metrics: BTMetricsPayload?
    public let effect: BTEffectRecord?
    public let rating: BTRatingRecord?
    public let action: BTActionRecord?
    public let expert: BTExpertAdvice?
}

// MARK: - Settings / Consent

enum BeautyTelemetrySettings {
    static var telemetryEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "bt_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "bt_enabled") }
    }
    static var researchConsent: Bool {
        get { UserDefaults.standard.object(forKey: "bt_research") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "bt_research") }
    }
    static var differentialPrivacyEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "bt_dp") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "bt_dp") }
    }
    static var epsilon: Double {
        get { UserDefaults.standard.object(forKey: "bt_eps") as? Double ?? 3.0 }
        set { UserDefaults.standard.set(newValue, forKey: "bt_eps") }
    }
}

// MARK: - Normalization Helpers

enum LandmarkNormalizer {
    static func normalize(points: [String: [CGPoint]]) -> (ipd: Double, norm: [String: [[Double]]])? {
        guard let left = points["leftEye"], let right = points["rightEye"], !left.isEmpty, !right.isEmpty else { return nil }
        let lc = avg(left), rc = avg(right)
        let ipd = hypot(Double(lc.x - rc.x), Double(lc.y - rc.y))
        guard ipd > 1e-6 else { return nil }
        var out: [String: [[Double]]] = [:]
        for (k, arr) in points {
            out[k] = arr.map { p in
                let dx = (Double(p.x) - Double(lc.x)) / ipd
                let dy = (Double(p.y) - Double(lc.y)) / ipd
                // 量化压缩到 1e-3
                return [Double(round(dx*1000)/1000), Double(round(dy*1000)/1000)]
            }
        }
        return (ipd, out)
    }
    private static func avg(_ pts: [CGPoint]) -> CGPoint {
        guard !pts.isEmpty else { return .zero }
        let sx = pts.map{$0.x}.reduce(0, +)
        let sy = pts.map{$0.y}.reduce(0, +)
        return CGPoint(x: sx/CGFloat(pts.count), y: sy/CGFloat(pts.count))
    }
}

// MARK: - Service

final class BeautyTelemetryService {
    static let shared = BeautyTelemetryService()
    private let queue = DispatchQueue(label: "beauty.telemetry.queue")
    private let fileManager = FileManager.default
    private lazy var storeURL: URL = {
        let dir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("BTStore", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("events.jsonl")
    }()
    private var sessionId: String = UUID().uuidString

    func beginNewSession() { sessionId = UUID().uuidString }

    private func envelope() -> BTSessionEnvelope {
        let dev = UIDevice.current.model
        let os = "iOS " + UIDevice.current.systemVersion
        let locale = Locale.current.identifier
        let idfv = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceHash = SignatureHelper.sha256Hex(idfv.data(using: .utf8) ?? Data())
        return BTSessionEnvelope(sessionId: sessionId, timestamp: Date(), device: dev, os: os, locale: locale, deviceHash: deviceHash)
    }

    private(set) var lastQC: BTCaptureQC?
    func recordCapture(qc: BTCaptureQC) {
        guard BeautyTelemetrySettings.telemetryEnabled else { return }
        lastQC = qc
        let event = BTEvent(kind: .capture, session: envelope(), captureQC: qc, geom: nil, metrics: nil, effect: nil, rating: nil, action: nil, expert: nil)
        persist(event)
    }

    func recordGeometry(points: [String: [CGPoint]], metrics: BTMetricsPayload?) {
        guard BeautyTelemetrySettings.telemetryEnabled else { return }
        guard let (ipd, norm) = LandmarkNormalizer.normalize(points: points) else { return }
        var geom = BTGeomPayload(ipd: ipd, points: norm)
        if BeautyTelemetrySettings.differentialPrivacyEnabled { geom = addNoise(geom) }
        let event = BTEvent(kind: .geometry, session: envelope(), captureQC: nil, geom: geom, metrics: metrics, effect: nil, rating: nil, action: nil, expert: nil)
        persist(event)
    }

    func recordEffect(_ record: BTEffectRecord) {
        guard BeautyTelemetrySettings.telemetryEnabled else { return }
        let event = BTEvent(kind: .effect, session: envelope(), captureQC: nil, geom: nil, metrics: nil, effect: record, rating: nil, action: nil, expert: nil)
        persist(event)
    }

    func recordRating(_ rating: BTRatingRecord) {
        guard BeautyTelemetrySettings.telemetryEnabled else { return }
        let event = BTEvent(kind: .rating, session: envelope(), captureQC: nil, geom: nil, metrics: nil, effect: nil, rating: rating, action: nil, expert: nil)
        persist(event)
    }

    func recordAction(_ action: BTActionRecord) {
        guard BeautyTelemetrySettings.telemetryEnabled else { return }
        let event = BTEvent(kind: .action, session: envelope(), captureQC: nil, geom: nil, metrics: nil, effect: nil, rating: nil, action: action, expert: nil)
        persist(event)
    }

    func recordExpert(_ expert: BTExpertAdvice) {
        guard BeautyTelemetrySettings.telemetryEnabled else { return }
        let event = BTEvent(kind: .expert, session: envelope(), captureQC: nil, geom: nil, metrics: nil, effect: nil, rating: nil, action: nil, expert: expert)
        persist(event)
    }

    // MARK: - Persistence
    private func persist(_ event: BTEvent) {
        queue.async {
            do {
                let data = try JSONEncoder().encode(event)
                if self.fileManager.fileExists(atPath: self.storeURL.path) {
                    let handle = try FileHandle(forWritingTo: self.storeURL)
                    try handle.seekToEnd()
                    try handle.write(data)
                    try handle.write("\n".data(using: .utf8)!)
                    try handle.close()
                } else {
                    try (data + "\n".data(using: .utf8)!).write(to: self.storeURL)
                }
            } catch {
                // swallow
            }
        }
    }

    func exportAll() -> URL? {
        return fileManager.fileExists(atPath: storeURL.path) ? storeURL : nil
    }

    func deleteAll() {
        try? fileManager.removeItem(at: storeURL)
    }

    // MARK: - Differential Privacy
    private func addNoise(_ geom: BTGeomPayload) -> BTGeomPayload {
        let eps = max(0.5, BeautyTelemetrySettings.epsilon)
        var out = geom.points
        for (k, arr) in geom.points {
            out[k] = arr.map { pair in
                let nx = pair[0] + Laplace.sample(scale: 1.0/eps)
                let ny = pair[1] + Laplace.sample(scale: 1.0/eps)
                return [Double(round(nx*1000)/1000), Double(round(ny*1000)/1000)]
            }
        }
        return BTGeomPayload(ipd: geom.ipd, points: out)
    }
}

// MARK: - Helper
enum SignatureHelper {
    static func sha256Hex(_ data: Data) -> String {
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}


