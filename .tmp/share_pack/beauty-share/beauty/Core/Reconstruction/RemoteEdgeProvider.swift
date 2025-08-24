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



