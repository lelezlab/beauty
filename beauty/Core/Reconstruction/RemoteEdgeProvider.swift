import Foundation
import UIKit

final class RemoteEdgeClient: ReconstructionProvider {
    enum EdgeErr: LocalizedError { case badConfig, requestFailed, uploadFailed, timeout, notFound
        var errorDescription: String? {
            switch self {
            case .badConfig: return "Edge base URL missing"
            case .requestFailed: return "Edge request failed"
            case .uploadFailed: return "Edge upload failed"
            case .timeout: return "Edge timeout"
            case .notFound: return "Edge job not found"
            }
        }
    }

    private var base: String {
        (Bundle.main.object(forInfoDictionaryKey: "EdgeBaseURL") as? String) ?? ""
    }

    func reconstruct(from bundle: CaptureBundle) async throws -> FaceMesh3D {
        if AppFlags.isProofRunning { throw EdgeErr.timeout }
        guard !base.isEmpty else { throw EdgeErr.badConfig }
        // 1) request upload urls
        let deviceId = DeviceHash.anon()
        let reqURL = URL(string: base + "request-urls")!
        var req = URLRequest(url: reqURL); req.httpMethod = "POST"; req.addValue(deviceId, forHTTPHeaderField: "x-device-id")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["mode": "triView", "device_id": deviceId, "ext": "jpg"])
        let (d1, r1) = try await URLSession.shared.data(for: req)
        guard (r1 as? HTTPURLResponse)?.statusCode ?? 500 < 300,
              let o = try JSONSerialization.jsonObject(with: d1) as? [String: Any],
              let jobId = o["job_id"] as? String,
              let up = o["upload_urls"] as? [String: String] else { throw EdgeErr.requestFailed }

        // 2) upload tri-view
        let imgs: [String: UIImage?] = ["front": bundle.front, "left": bundle.left, "right": bundle.right]
        for (k, v) in imgs {
            guard let urlStr = up[k], let url = URL(string: urlStr), let img = v, let data = img.jpegData(compressionQuality: 0.9) else { throw EdgeErr.uploadFailed }
            var put = URLRequest(url: url); put.httpMethod = "PUT"; put.httpBody = data; put.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            let (_, resp) = try await URLSession.shared.data(for: put)
            guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 300 else { throw EdgeErr.uploadFailed }
        }

        // 3) submit
        let subURL = URL(string: base + "submit")!; var sreq = URLRequest(url: subURL); sreq.httpMethod = "POST"; sreq.addValue(deviceId, forHTTPHeaderField: "x-device-id")
        sreq.httpBody = try? JSONSerialization.data(withJSONObject: ["job_id": jobId, "meta": ["device_id": deviceId, "mode": "triView"], "inputs": o["inputs"] ?? [:]])
        let _ = try await URLSession.shared.data(for: sreq)

        // 4) poll status
        let statusURL = URL(string: base + "status?id=\(jobId)")!
        var outputs: [String: Any]? = nil
        let start = Date()
        while Date().timeIntervalSince(start) < 60 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let (d, _) = try await URLSession.shared.data(from: statusURL)
            if let obj = try JSONSerialization.jsonObject(with: d) as? [String: Any], let st = obj["status"] as? String {
                if st == "done" { outputs = obj["outputs"] as? [String: Any]; break }
                if st == "error" { throw EdgeErr.requestFailed }
            }
        }
        guard let outs = outputs else { throw EdgeErr.timeout }

        // 5) cache downloads
        let cacheDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("ReconCache/\(jobId)", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        func download(_ key: String, name: String) async throws -> URL? {
            guard let path = outs[key] as? String, let u = URL(string: path) else { return nil }
            let (tmp, _) = try await URLSession.shared.download(from: u)
            let dest = cacheDir.appendingPathComponent(name)
            _ = try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tmp, to: dest)
            return dest
        }
        let glbURL = try await download("mesh_glb", name: "mesh.glb")
        let texURL = try await download("texture_png", name: "texture.png")
        // write last_job json
        let last = cacheDir.appendingPathComponent("last_job.json")
        if let jd = try? JSONSerialization.data(withJSONObject: ["id": jobId, "outputs": outs], options: [.prettyPrinted]) { try? jd.write(to: last) }

        // 6) parse glb → FaceMesh3D
        if let g = glbURL, !AppFlags.isProofRunning {
            do {
                let node = try GLBLoader.loadFaceNode(from: g)
                if let geo = node.geometry ?? node.childNodes.first?.geometry {
                    var mesh = GLBLoader.scnGeometryToFaceMesh(geo)
                    if let t = texURL { mesh.albedo = UIImage(contentsOfFile: t.path) }
                    mesh.metadata = ["source": "edge", "job_id": jobId, "cache": cacheDir.path]
                    UserDefaults.standard.set("remote", forKey: "edge_provider")
                    UserDefaults.standard.set(jobId, forKey: "edge_job_id")
                    UserDefaults.standard.set("done", forKey: "edge_last_result")
                    UserDefaults.standard.set(Date().timeIntervalSince(start) * 1000.0, forKey: "edge_latency_ms")
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: g.path), let gsz = attrs[.size] as? NSNumber { UserDefaults.standard.set(gsz.intValue, forKey: "edge_glb_size") }
                    if let t = texURL, let attrs = try? FileManager.default.attributesOfItem(atPath: t.path), let tsz = attrs[.size] as? NSNumber { UserDefaults.standard.set(tsz.intValue, forKey: "edge_tex_size") }
                    return mesh
                }
            } catch {
                DebugLog.log("remote.parse: \(error.localizedDescription)")
                UserDefaults.standard.set("parse", forKey: "edge_error_domain")
                UserDefaults.standard.set(error.localizedDescription, forKey: "edge_error_message")
            }
        }
        // fallback
        DebugLog.log("remote.cache: fallback_to_mock")
        UserDefaults.standard.set("cache", forKey: "edge_error_domain")
        UserDefaults.standard.set("fallback_to_mock", forKey: "edge_error_message")
        return try await MockEdgeProvider.reconstructDemo(bundle: bundle)
    }
}

import Foundation
import UIKit

enum RemoteEdgeProvider {
    struct Response: Decodable {
        struct MeshData: Decodable { let vertices: [[Float]]; let indices: [[UInt32]]; let uv: [[Float]]? }
        let mesh: MeshData?
        let texture_url: String?
        let gltf_url: String?
        let scale_m_per_unit: Float?
        let source: String?
    }

    static func reconstructTriView(bundle: CaptureBundle, endpoint: URL) async throws -> FaceMesh3D {
        // Upload or use existing URLs: for demo we assume client already has sample URLs in metadata or use local mock uploader.
        var body: [String: Any] = [
            "ipd_mm": bundle.ipdNorm ?? 62.0,
            "camera": ["model": "iPhone", "focal_mm": bundle.camera?.focalEqMM ?? 26.0]
        ]
        func tempURL(_ img: UIImage?) -> String? {
            guard let d = img?.jpegData(compressionQuality: 0.9) else { return nil }
            let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".jpg")
            try? d.write(to: tmp)
            return tmp.absoluteString
        }
        body["front_url"] = tempURL(bundle.front)
        body["left_url"] = tempURL(bundle.left)
        body["right_url"] = tempURL(bundle.right)

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let data = try await EdgeClient.postJSON(url: endpoint, body: body, timeout: 2.5, retries: 2)
        let resp = try JSONDecoder().decode(Response.self, from: data)
        if let m = resp.mesh {
            let v = m.vertices.map { SIMD3<Float>($0[0], $0[1], $0[2]) }
            let f = m.indices.map { SIMD3<UInt32>($0[0], $0[1], $0[2]) }
            let uv = m.uv?.map { SIMD2<Float>($0[0], $0[1]) }
            var texImg: UIImage? = nil
            if let turl = resp.texture_url, let u = URL(string: turl), let d = try? Data(contentsOf: u) { texImg = UIImage(data: d) }
            var mesh = FaceMesh3D(vertices: v, faces: f, uvs: uv, albedo: texImg, mmPerPixel: CalibrationManager.shared.state.scaleMMPerPixel)
            mesh.metadata = ["source": "edge"]
            return mesh
        }
        throw URLError(.badServerResponse)
    }
}



