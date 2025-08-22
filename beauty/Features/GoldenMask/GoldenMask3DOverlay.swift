import SwiftUI
import SceneKit
import simd

struct GoldenMask3DOverlay: UIViewRepresentable {
    let mesh: FaceMesh3D?
    var t1: Float = 1.0
    var t2: Float = 3.0
    var alpha: Float = 0.95
    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.backgroundColor = .black
        v.allowsCameraControl = true
        v.scene = SCNScene()
        return v
    }
    func updateUIView(_ view: SCNView, context: Context) {
        guard let _ = mesh else { return }
        view.scene = SCNScene()
        // 读取黄金面罩 OBJ 与 anchors_3d.json
        var gm: OBJMesh? = nil
        if let objURL = Bundle.main.url(forResource: "specs/golden_mask/golden_mask_3d", withExtension: "obj") {
            gm = OBJParser.load(url: objURL)
        }
        // 简化：若无真实网格，显示球体；否则以平均偏差上色（占位）
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
            // 生成每顶点颜色：使用真实毫米偏差（黄金 → 用户网格配准）
            var colors: [SIMD4<Float>] = Array(repeating: SIMD4<Float>(0.2, 0.8, 0.7, alpha), count: gm.vertices.count)
            if let user = mesh {
                let userAnchors = user.metadata?["anchors3d"] as? [String:Int]
                let goldenAnchors = anchors?.indices
                colors = GoldenMaskAlignment3D.colorize(golden: gm, user: user, anchorsGolden: goldenAnchors, anchorsUser: userAnchors, t1: t1, t2: t2, alpha: alpha)
            }
            let colorData = Data(bytes: colors, count: colors.count*MemoryLayout<SIMD4<Float>>.size)
            let colorSource = SCNGeometrySource(data: colorData, semantic: .color, vectorCount: colors.count, usesFloatComponents: true, componentsPerVector: 4, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<SIMD4<Float>>.size)
            let geom = SCNGeometry(sources: [src, colorSource], elements: elements)
            geom.firstMaterial = SCNMaterial()
            geom.firstMaterial?.isDoubleSided = true
            let node = SCNNode(geometry: geom)
            view.scene?.rootNode.addChildNode(node)
        } else {
            let node = SCNNode(geometry: SCNSphere(radius: 0.5))
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemTeal
            view.scene?.rootNode.addChildNode(node)
        }
        let cam = SCNCamera(); cam.zFar = 1000; let camNode = SCNNode(); camNode.camera = cam; camNode.position = SCNVector3(0,0,2.0); view.scene?.rootNode.addChildNode(camNode)
        let light = SCNLight(); light.type = .omni; let lightNode = SCNNode(); lightNode.light = light; lightNode.position = SCNVector3(1,1,2); view.scene?.rootNode.addChildNode(lightNode)
    }
}


