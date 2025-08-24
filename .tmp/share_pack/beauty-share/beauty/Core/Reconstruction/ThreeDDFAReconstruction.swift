import Foundation
import UIKit

final class ThreeDDFAReconstruction: ReconstructionProvider {
    struct Resp: Decodable {
        let vertices: [[Float]]
        let indices: [[Int]]
        let uv: [[Float]]?
        let landmarks68: [[Float]]?
        let params: [String: Float]?
    }

    func reconstruct(from bundle: CaptureBundle) async throws -> FaceMesh3D {
        guard let urlStr = Bundle.main.object(forInfoDictionaryKey: "ThreeDDFAURL") as? String,
              let url = URL(string: urlStr), !urlStr.isEmpty else {
            throw NSError(domain: "ThreeDDFA", code: -1, userInfo: [NSLocalizedDescriptionKey: "ThreeDDFAURL not configured in Info.plist"]) }
        // Prefer front/left/right images; base64 encode
        let imgs: [UIImage] = [bundle.front, bundle.left, bundle.right].compactMap { $0 }
        guard !imgs.isEmpty else { throw NSError(domain: "ThreeDDFA", code: -2, userInfo: [NSLocalizedDescriptionKey: "No images in bundle"]) }
        let arr = imgs.compactMap { $0.jpegData(compressionQuality: 0.85)?.base64EncodedString() }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // CaptureBundle.CameraParams 当前不含 retopo，使用统一模板常量
        let body: [String: Any] = ["images": arr, "retopo": "TEMPLATE_FLAME_5023"]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        let r = try JSONDecoder().decode(Resp.self, from: data)
        // Build mesh (mm units not known → keep as-is)
        let vertices = r.vertices.map { SIMD3<Float>($0[0], $0[1], $0[2]) }
        let faces = r.indices.map { SIMD3<UInt32>(UInt32($0[0]), UInt32($0[1]), UInt32($0[2])) }
        let uvs = r.uv?.map { SIMD2<Float>($0[0], $0[1]) }
        let mesh = FaceMesh3D(vertices: vertices, faces: faces, uvs: uvs, albedo: bundle.front, mmPerPixel: nil, topologyId: "3DDFA_V2", calibrationMMPerPX: nil, neutralPoseCoeffs: r.params, metadata: ["source": "triView"])
        return mesh
    }
}


