import SwiftUI
import SceneKit
import simd

struct GoldenMask3DOverlay: UIViewRepresentable {
    let mesh: FaceMesh3D?
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
            // 构造 SceneKit 几何
            let src = SCNGeometrySource(vertices: gm.vertices.map { SCNVector3($0.x, $0.y, $0.z) })
            let elements: [SCNGeometryElement] = {
                let data = Data(bytes: gm.faces.flatMap { [$0.x, $0.y, $0.z] }, count: gm.faces.count*3*MemoryLayout<UInt32>.size)
                return [SCNGeometryElement(data: data, primitiveType: .triangles, primitiveCount: gm.faces.count, bytesPerIndex: MemoryLayout<UInt32>.size)]
            }()
            let geom = SCNGeometry(sources: [src], elements: elements)
            // 简化热力：全部顶点同色（后续接锚点偏差）
            geom.firstMaterial = SCNMaterial()
            geom.firstMaterial?.diffuse.contents = UIColor.systemTeal
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


