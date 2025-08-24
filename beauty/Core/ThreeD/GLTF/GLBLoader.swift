import Foundation
import SceneKit

enum GLBLoader {
    static func loadFaceNode(from url: URL) throws -> SCNNode {
        // Prefer GLTF (.glb/.gltf) via GLTFSceneKit if available
        #if canImport(GLTFSceneKit)
        if let scene = try? GLTFSceneSource(url: url).scene() { return scene.rootNode }
        #endif
        // Fallback to SceneKit native with URL-based load and autorelease to reduce peak memory
        let scene: SCNScene = try autoreleasepool(invoking: {
            let src = SCNSceneSource(url: url, options: [
                SCNSceneSource.LoadingOption.checkConsistency: false,
                SCNSceneSource.LoadingOption.convertUnitsToMeters: true
            ])
            guard let s = try src?.scene(options: [
                SCNSceneSource.LoadingOption.createNormalsIfAbsent: true
            ]) else {
                throw NSError(domain: "glb.parse", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load GLB"])
            }
            return s
        })
        let root = scene.rootNode
        // Detach scene graph to allow scene to deallocate sooner
        return root
    }

    static func scnGeometryToFaceMesh(_ geo: SCNGeometry) -> FaceMesh3D {
        var vertices: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>]? = nil
        var faces: [SIMD3<UInt32>] = []
        for src in geo.sources {
            switch src.semantic {
            case .vertex:
                let stride = src.dataStride
                let offset = src.dataOffset
                let vectorCount = src.vectorCount
                let bytes = src.data as NSData
                for i in 0..<vectorCount {
                    let base = offset + i*stride
                    var x: Float = 0, y: Float = 0, z: Float = 0
                    bytes.getBytes(&x, range: NSRange(location: base + 0*MemoryLayout<Float>.size, length: MemoryLayout<Float>.size))
                    bytes.getBytes(&y, range: NSRange(location: base + 1*MemoryLayout<Float>.size, length: MemoryLayout<Float>.size))
                    bytes.getBytes(&z, range: NSRange(location: base + 2*MemoryLayout<Float>.size, length: MemoryLayout<Float>.size))
                    vertices.append(SIMD3<Float>(x, y, z))
                }
            case .texcoord:
                var arr: [SIMD2<Float>] = []
                let stride = src.dataStride
                let offset = src.dataOffset
                let vectorCount = src.vectorCount
                let bytes = src.data as NSData
                for i in 0..<vectorCount {
                    let base = offset + i*stride
                    var u: Float = 0, v: Float = 0
                    bytes.getBytes(&u, range: NSRange(location: base + 0*MemoryLayout<Float>.size, length: MemoryLayout<Float>.size))
                    bytes.getBytes(&v, range: NSRange(location: base + 1*MemoryLayout<Float>.size, length: MemoryLayout<Float>.size))
                    arr.append(SIMD2<Float>(u, 1 - v))
                }
                uvs = arr
            default: break
            }
        }
        for elem in geo.elements where elem.primitiveType == .triangles {
            let indexCount = elem.primitiveCount * 3
            var local: [UInt32] = Array(repeating: 0, count: indexCount)
            _ = local.withUnsafeMutableBytes { mb in
                elem.data.copyBytes(to: mb)
            }
            for i in stride(from: 0, to: indexCount, by: 3) {
                faces.append(SIMD3(local[i], local[i+1], local[i+2]))
            }
        }
        return FaceMesh3D(vertices: vertices, faces: faces, uvs: uvs, albedo: nil, mmPerPixel: CalibrationManager.shared.state.scaleMMPerPixel)
    }
}
