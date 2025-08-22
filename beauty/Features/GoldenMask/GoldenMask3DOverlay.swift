import SwiftUI
import SceneKit

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
        guard mesh != nil else { return }
        // 占位：显示一个球体并根据 mm 偏差着色（真实实现接 SceneKit 网格）
        view.scene = SCNScene()
        let node = SCNNode(geometry: SCNSphere(radius: 0.5))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemTeal
        view.scene?.rootNode.addChildNode(node)
        let cam = SCNCamera(); cam.zFar = 1000; let camNode = SCNNode(); camNode.camera = cam; camNode.position = SCNVector3(0,0,2.0); view.scene?.rootNode.addChildNode(camNode)
        let light = SCNLight(); light.type = .omni; let lightNode = SCNNode(); lightNode.light = light; lightNode.position = SCNVector3(1,1,2); view.scene?.rootNode.addChildNode(lightNode)
    }
}


