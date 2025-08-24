import Foundation
import UIKit

enum DebugLog {
    private static var queue = DispatchQueue(label: "debug.log.queue")
    private static var cached: [String] = []

    static func log(_ message: String) {
        let line = "[\(timestamp())] \(message)\n"
        queue.async {
            cached.append(line)
            // keep last 2000 lines in memory
            if cached.count > 2000 { cached.removeFirst(cached.count - 2000) }
            appendToFile(line)
        }
    }

    static func exportURL() -> URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("proof", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("debug.log")
    }

    static func clear() {
        queue.async {
            cached.removeAll()
            try? FileManager.default.removeItem(at: exportURL())
        }
    }

    private static func appendToFile(_ text: String) {
        let url = exportURL()
        if let data = text.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: url.path) {
                if let h = try? FileHandle(forWritingTo: url) { defer { try? h.close() }; try? h.seekToEnd(); try? h.write(contentsOf: data) }
            } else {
                try? data.write(to: url)
            }
        }
    }

    private static func timestamp() -> String {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df.string(from: Date())
    }
}


