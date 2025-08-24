import Foundation

enum ModelFetcher {
    static func applicationSupportModelsDir() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("ModelsOverride", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func fetchAll() async -> Bool {
        guard let lockURL = Bundle.main.url(forResource: "models.lock", withExtension: "json", subdirectory: "Resources/Models") ??
                Bundle.main.url(forResource: "models.lock", withExtension: "json", subdirectory: "Models") else {
            return false
        }
        guard let data = try? Data(contentsOf: lockURL),
              let lock = try? JSONDecoder().decode(ModelLock.self, from: data) else { return false }
        let dir = applicationSupportModelsDir()
        var okAll = true
        for it in lock.models {
            guard let url = URL(string: it.url) else { okAll = false; continue }
            let dest = dir.appendingPathComponent(it.dest)
            try? FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            do {
                let (d, _) = try await URLSession.shared.data(from: url)
                try d.write(to: dest)
                let good = (try? Hasher.verifySHA256(filePath: dest.path, hex: it.sha256)) ?? false
                if !good { okAll = false }
            } catch { okAll = false }
        }
        UserDefaults.standard.set(okAll, forKey: "models_fetch_ok")
        return okAll
    }
}



