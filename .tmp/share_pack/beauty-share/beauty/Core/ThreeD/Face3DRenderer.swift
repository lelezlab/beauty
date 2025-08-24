import SceneKit

public final class Face3DRenderer {
    private let scene = SCNScene()
    private let node = SCNNode()
    public init() { scene.rootNode.addChildNode(node) }
    public func setupPreview(in view: SCNView) {
        view.scene = scene
        view.allowsCameraControl = true
        view.backgroundColor = .black
    }
    public func render(mesh: [SIMD3<Float>], faces: [SIMD3<UInt32>]) {
        // Placeholder geometry (empty); integrate with real buffers later
        node.geometry = SCNSphere(radius: 0.5)
    }
}


