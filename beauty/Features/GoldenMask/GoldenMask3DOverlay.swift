import SwiftUI
import SceneKit
import simd

struct GoldenMask3DOverlay: UIViewRepresentable {
    enum Mode { case heatmap, wireframe, texture, mask }
    let mesh: FaceMesh3D?
    var t1: Float = 1.0
    var t2: Float = 3.0
    var alpha: Float = 0.95
    var mode: Mode = .heatmap
    var lineWidth: CGFloat = 1.0
    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.backgroundColor = .black
        v.allowsCameraControl = true
        v.scene = SCNScene()
        return v
    }
    func updateUIView(_ view: SCNView, context: Context) {
        guard let userMesh = mesh else { return }
        view.scene = SCNScene()
        // 读取黄金面罩 OBJ 与 anchors_3d.json
        var gm: OBJMesh? = nil
        if let objURL = Bundle.main.url(forResource: "specs/golden_mask/golden_mask_3d", withExtension: "obj") {
            gm = OBJParser.load(url: objURL)
        }
        // 若黄金面罩资源缺失，则退化为用户网格的半透明蒙版/线框覆盖，避免黑屏
        if let gm = gm {
            // anchors_3d.json → 关键点索引
            var anchors: Anchors3D? = nil
            if let aurl = Bundle.main.url(forResource: "specs/golden_mask/anchors_3d", withExtension: "json") {
                anchors = Anchors3DParser.load(url: aurl)
            }
            // 构造 SceneKit 几何
            let src = SCNGeometrySource(vertices: gm.vertices.map { SCNVector3($0.x, $0.y, $0.z) })
            let elements: [SCNGeometryElement] = {
                let data = Data(bytes: gm.faces.flatMap { [$0.x, $0.y, $0.z] }, count: gm.faces.count*3*MemoryLayout<UInt32>.size)
                return [SCNGeometryElement(data: data, primitiveType: .triangles, primitiveCount: gm.faces.count, bytesPerIndex: MemoryLayout<UInt32>.size)]
            }()
            var sources: [SCNGeometrySource] = [src]
            var geom: SCNGeometry
            switch mode {
            case .heatmap:
                // 生成每顶点颜色：使用真实毫米偏差（黄金 → 用户网格配准）
                var colors: [SIMD4<Float>] = Array(repeating: SIMD4<Float>(0.2, 0.8, 0.7, alpha), count: gm.vertices.count)
                if let user = mesh {
                    let userAnchors = user.metadata?["anchors3d"] as? [String:Int]
                    let goldenAnchors = anchors?.indices
                    colors = GoldenMaskAlignment3D.colorize(golden: gm, user: user, anchorsGolden: goldenAnchors, anchorsUser: userAnchors, t1: t1, t2: t2, alpha: alpha)
                }
                let colorData = Data(bytes: colors, count: colors.count*MemoryLayout<SIMD4<Float>>.size)
                let colorSource = SCNGeometrySource(data: colorData, semantic: .color, vectorCount: colors.count, usesFloatComponents: true, componentsPerVector: 4, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<SIMD4<Float>>.size)
                sources.append(colorSource)
                geom = SCNGeometry(sources: sources, elements: elements)
                geom.firstMaterial = SCNMaterial()
                geom.firstMaterial?.lightingModel = .constant
                geom.firstMaterial?.isDoubleSided = true
            case .wireframe:
                geom = SCNGeometry(sources: sources, elements: elements)
                let m = SCNMaterial(); m.diffuse.contents = UIColor.white.withAlphaComponent(CGFloat(alpha))
                m.isDoubleSided = true
                m.fillMode = .lines
                geom.firstMaterial = m
            case .texture:
                geom = SCNGeometry(sources: sources, elements: elements)
                let m = SCNMaterial()
                // 使用用户纹理，若存在
                m.diffuse.contents = mesh?.albedo ?? UIColor.white.withAlphaComponent(0.2)
                m.transparency = CGFloat(alpha)
                m.isDoubleSided = true
                geom.firstMaterial = m
            case .mask:
                geom = SCNGeometry(sources: sources, elements: elements)
                let m = SCNMaterial(); m.diffuse.contents = UIColor.white; m.transparency = CGFloat(alpha)
                m.isDoubleSided = true
                geom.firstMaterial = m
            }
            let node = SCNNode(geometry: geom)
            view.scene?.rootNode.addChildNode(node)
        } else {
            let vertsMeters: [SIMD3<Float>] = userMesh.vertices.map { Units.mmToMeters($0) }
            let vsrc = SCNGeometrySource(vertices: vertsMeters.map { SCNVector3($0.x,$0.y,$0.z) })
            let idx: [UInt32] = (userMesh.indices ?? userMesh.faces).flatMap { [$0.x, $0.y, $0.z] }
            let data = idx.withUnsafeBufferPointer { Data(buffer: $0) }
            let elem = SCNGeometryElement(data: data, primitiveType: .triangles, primitiveCount: idx.count/3, bytesPerIndex: MemoryLayout<UInt32>.size)
            let g = SCNGeometry(sources: [vsrc], elements: [elem])
            let m = SCNMaterial()
            switch mode {
            case .wireframe, .mask:
                m.diffuse.contents = UIColor.white.withAlphaComponent(CGFloat(alpha))
                m.isDoubleSided = true
                m.fillMode = .lines
            case .texture:
                m.diffuse.contents = userMesh.albedo ?? UIColor.white.withAlphaComponent(0.2)
                m.isDoubleSided = true
            case .heatmap:
                m.diffuse.contents = UIColor.systemTeal.withAlphaComponent(CGFloat(alpha))
                m.isDoubleSided = true
            }
            g.firstMaterial = m
            let n = SCNNode(geometry: g)
            view.scene?.rootNode.addChildNode(n)
        }
        let cam = SCNCamera(); cam.zFar = 1000; let camNode = SCNNode(); camNode.camera = cam; camNode.position = SCNVector3(0,0,2.0); view.scene?.rootNode.addChildNode(camNode)
        let light = SCNLight(); light.type = .omni; let lightNode = SCNNode(); lightNode.light = light; lightNode.position = SCNVector3(1,1,2); view.scene?.rootNode.addChildNode(lightNode)
    }
}


