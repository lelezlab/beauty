import Foundation

enum Telemetry {
    struct Event: Codable { let name: String; let timestamp: Date; let params: [String: String] }
    static func log(_ name: String, _ params: [String: String]) {
        let event = Event(name: name, timestamp: Date(), params: params)
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Telemetry", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("events.jsonl")
        guard let lineBreak = "\n".data(using: .utf8), let data = try? JSONEncoder().encode(event) else { return }
        let line = data + lineBreak
        if fm.fileExists(atPath: file.path) {
            if let handle = try? FileHandle(forWritingTo: file) {
                handle.seekToEndOfFile()
                handle.write(line)
                try? handle.close()
            }
        } else {
            _ = try? line.write(to: file)
        }
    }
}


