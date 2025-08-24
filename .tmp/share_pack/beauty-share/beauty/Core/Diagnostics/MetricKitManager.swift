import Foundation
import MetricKit

final class MetricKitManager: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricKitManager()
    private let storeURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("MXReports", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("summary.json")
    }()

    func activate() {
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        let summary = payloads.map { $0.dictionaryRepresentation() }
        if let data = try? JSONSerialization.data(withJSONObject: summary, options: []) { try? data.write(to: storeURL) }
        // TODO: use telemetry uploader to send mx_report (summary only)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {}
}


