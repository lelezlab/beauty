import Foundation

enum Telemetry {
    struct Event: Codable { let name: String; let timestamp: Date; let params: [String: String] }
    static func log(_ name: String, _ params: [String: String]) {
        let event = Event(name: name, timestamp: Date(), params: params)
        do {
            let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Telemetry", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let file = dir.appendingPathComponent("events.jsonl")
            let data = try JSONEncoder().encode(event)
            if FileManager.default.fileExists(atPath: file.path) {
                let handle = try FileHandle(forWritingTo: file)
                try handle.seekToEnd()
                try handle.write(data + "\n".data(using: .utf8)!)
                try handle.close()
            } else {
                try (data + "\n".data(using: .utf8)!).write(to: file)
            }
        } catch {
            // swallow; local only
        }
    }
}


