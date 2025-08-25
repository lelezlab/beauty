import Foundation

struct ModelItem: Decodable { let id: String; let dest: String; let sha256: String; let url: String }
struct ModelLock: Decodable { let models: [ModelItem] }

enum ModelError: Error { case missingLock, fileMissing(String), hashMismatch(String) }

/// Manage local model variants (fp16/int8) and dynamic selection by tier.
/// This is a placeholder registry; you can drop models into Resources/Models/ and fill actual filenames.
enum ModelRegistry {
    struct Entry { let fp16: String; let int8: String }

    // Logical names → file names (without path)
    static var detector = Entry(fp16: "retinaface_fp16.onnx", int8: "retinaface_int8.onnx")
    static var facemesh = Entry(fp16: "facemesh_fp16.onnx", int8: "facemesh_int8.onnx")
    static var arcface  = Entry(fp16: "arcface_ir50_fp16.onnx", int8: "arcface_ir50_int8.onnx")
    static var parsing  = Entry(fp16: "bisenet_fp16.onnx", int8: "bisenet_int8.onnx")
    static var depth    = Entry(fp16: "midas_small_fp16.onnx", int8: "midas_small_int8.onnx")

    static func url(for entry: Entry, tier: PerfTier) -> URL? {
        let name = (tier == .H || tier == .M) ? entry.fp16 : entry.int8
        return Bundle.main.url(forResource: "Models/\(name)", withExtension: nil)
    }

    // Lock reader and integrity checker
    static func path(for id: String) throws -> String {
        let lockURL = Bundle.main.url(forResource: "models.lock", withExtension: "json", subdirectory: "Resources/Models") ??
                      Bundle.main.url(forResource: "models.lock", withExtension: "json", subdirectory: "Models") ??
                      Bundle.main.url(forResource: "models.lock.seed", withExtension: "json", subdirectory: "Resources/Models")
        let lockData: Data
        if let u = lockURL, let d = try? Data(contentsOf: u) {
            lockData = d
        } else {
            // Embedded minimal seed to avoid user action on first run
            let seed = """
            {"models":[
              {"id":"facemesh_mediapipe_task","dest":"Resources/Models/facemesh/face_landmarker.task","sha256":"d41d8cd98f00b204e9800998ecf8427e","url":""},
              {"id":"arcface_ir50","dest":"Resources/Models/arcface/arcface_ir50.onnx","sha256":"d41d8cd98f00b204e9800998ecf8427e","url":""},
              {"id":"face_parsing_bisenet","dest":"Resources/Models/face_parsing/bisenet_fp16.onnx","sha256":"d41d8cd98f00b204e9800998ecf8427e","url":""},
              {"id":"midas_s","dest":"Resources/Models/midas/midas_small.onnx","sha256":"d41d8cd98f00b204e9800998ecf8427e","url":""}
            ]}
            """
            lockData = seed.data(using: .utf8) ?? Data()
        }
        let mlock = try JSONDecoder().decode(ModelLock.self, from: lockData)
        guard let it = mlock.models.first(where: { $0.id == id }) else { throw ModelError.missingLock }
        let dir = (it.dest as NSString).deletingLastPathComponent
        let name = (it.dest as NSString).lastPathComponent
        // Prefer Application Support override
        let override = ModelFetcher.applicationSupportModelsDir().appendingPathComponent(it.dest).path
        if FileManager.default.fileExists(atPath: override) {
            if try !Hasher.verifySHA256(filePath: override, hex: it.sha256) { throw ModelError.hashMismatch(it.dest) }
            return override
        }
        guard let path = Bundle.main.path(forResource: name, ofType: nil, inDirectory: dir) else { throw ModelError.fileMissing(it.dest) }
        if try !Hasher.verifySHA256(filePath: path, hex: it.sha256) { throw ModelError.hashMismatch(it.dest) }
        return path
    }
}


