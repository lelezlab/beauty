import SwiftUI
import SceneKit

struct Face3DPreviewView: View {
    @State private var meshAvailable: Bool = CaptureStore.shared.lastMesh != nil
    @State private var isComputing: Bool = false
    @State private var lastError: String? = nil
    @State private var t1: Double = 1.0
    @State private var t2: Double = 3.0
    @State private var alpha: Double = 0.95
    @State private var overlayMode: GoldenMask3DOverlay.Mode = .heatmap
    @State private var showWireframe: Bool = false
    @State private var showTexture: Bool = true
    @State private var beforeAfter: Double = 0.0 // 0 = before, 1 = after
    @State private var paramTip: Double = 0.0
    @State private var paramBridge: Double = 0.0

    var body: some View {
        ScrollView {
        VStack(spacing: 12) {
            if meshAvailable, let m = CaptureStore.shared.lastMesh {
                let sceneKey = "\(showWireframe)-\(showTexture)-\(beforeAfter)-\(paramTip)-\(paramBridge)-\(t1)-\(t2)-\(alpha)"
                SceneView(scene: makeScene(from: m), options: [.allowsCameraControl, .autoenablesDefaultLighting])
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .id(sceneKey)
                // 黄金面罩 3D 叠加（毫米热力）
                GoldenMask3DOverlay(mesh: m, t1: Float(t1), t2: Float(t2), alpha: Float(alpha), mode: overlayMode)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    Text("暂无人脸网格").font(.headline)
                    Text("当前设备不支持 TrueDepth，且三视图重建未启用。\(lastError != nil ? " (\(lastError!))" : "")").font(.footnote).foregroundStyle(.secondary)
                    Button("Retry Edge") { Task { await reconstructEdge() } }.buttonStyle(.bordered)
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
            HStack {
                Button(meshAvailable ? "重新生成" : "生成 3D 预览") {
                    Task { await reconstructIfPossible() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isComputing)
                if isComputing { ProgressView().padding(.leading, 6) }
                Spacer()
                Toggle("线框", isOn: $showWireframe).toggleStyle(.switch)
                Toggle("纹理", isOn: $showTexture).toggleStyle(.switch)
            }
            // 热力与透明度设置
            Group {
                HStack { Text("绿≤"); Slider(value: $t1, in: 0.5...2.0); Text(String(format: "%.1fmm", t1)) }
                HStack { Text("黄≤"); Slider(value: $t2, in: 2.0...5.0); Text(String(format: "%.1fmm", t2)) }
                HStack { Text("透明度"); Slider(value: $alpha, in: 0.2...1.0); Text(String(format: "%.2f", alpha)) }
                Picker("叠加模式", selection: $overlayMode) {
                    Text("Heatmap").tag(GoldenMask3DOverlay.Mode.heatmap)
                    Text("Wireframe").tag(GoldenMask3DOverlay.Mode.wireframe)
                    Text("Texture").tag(GoldenMask3DOverlay.Mode.texture)
                    Text("Mask").tag(GoldenMask3DOverlay.Mode.mask)
                }
                .pickerStyle(.segmented)
                HStack { Text("术前↔术后"); Slider(value: $beforeAfter, in: 0...1) }
                HStack { Text("tip_rotation"); Slider(value: $paramTip, in: -8...8); Text(String(format: "%.1f°", paramTip)) }
                HStack { Text("bridge_straighten"); Slider(value: $paramBridge, in: 0...1); Text(String(format: "%.2f", paramBridge)) }
            }
            .font(.caption)
            .padding(.horizontal, 4)
            Text("说明：当前为占位 3D 预览。真机将优先使用 ARKit 网格；无 TrueDepth 时将回退到三视图重建（未启用则显示空态）。")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        }
        .navigationTitle("3D 预览（实验）")
        .onAppear {
            meshAvailable = CaptureStore.shared.lastMesh != nil
            if !meshAvailable {
                Task { await reconstructIfPossible() }
            }
        }
    }

    private func reconstructIfPossible() async {
        guard !AppFlags.isProofRunning else { return }
        isComputing = true
        defer { isComputing = false }
        let _ = await ReconstructionOrchestrator.shared.reconstructAuto()
        await MainActor.run {
            meshAvailable = CaptureStore.shared.lastMesh != nil
            if !meshAvailable {
                lastError = UserDefaults.standard.string(forKey: "edge_error_domain")
            } else {
                showTexture = true
            }
        }
    }

    private func reconstructEdge() async {
        guard !AppFlags.isProofRunning else { return }
        isComputing = true
        defer { isComputing = false }
        let b = ReconstructionOrchestrator.shared.buildBundleFromCapture()
        // If no tri-view present, use samples
        if b.front == nil || b.left == nil || b.right == nil {
            if let m = try? await TriViewSampleProvider.reconstructMesh() { CaptureStore.shared.lastMesh = m }
        } else {
            if let m = try? await RemoteEdgeClient().reconstruct(from: b) { CaptureStore.shared.lastMesh = m }
        }
        await MainActor.run { meshAvailable = CaptureStore.shared.lastMesh != nil }
    }

    private func makeScene(from mesh: FaceMesh3D) -> SCNScene {
        let scene = SCNScene()
        let node = SCNNode()
        // Before/After blend (use TPSMorph)
        let after = TPSMorph.apply(to: mesh, params: .init(tip_rotation: paramTip, bridge_straighten: paramBridge))
        let blended = FaceMesh3D.blend(mesh, after, t: Float(beforeAfter))
        let vertsMeters: [SIMD3<Float>] = blended.vertices.map { Units.mmToMeters($0) }
        let verts = vertsMeters.map { SCNVector3($0.x, $0.y, $0.z) }
        let vsrc = SCNGeometrySource(vertices: verts)
        var sources: [SCNGeometrySource] = [vsrc]
        if let uvs = blended.uvs {
            let uvPoints = uvs.map { CGPoint(x: CGFloat($0.x), y: CGFloat(1 - $0.y)) }
            let uvsrc = SCNGeometrySource(textureCoordinates: uvPoints)
            sources.append(uvsrc)
        }
        let idx: [UInt32]
        if let idxTriples = blended.indices { idx = idxTriples.flatMap { [$0.x, $0.y, $0.z] } }
        else { idx = blended.faces.flatMap { [$0.x, $0.y, $0.z] } }
        let data = idx.withUnsafeBufferPointer { Data(buffer: $0) }
        let elem = SCNGeometryElement(data: data, primitiveType: .triangles, primitiveCount: idx.count/3, bytesPerIndex: MemoryLayout<UInt32>.size)
        let geo = SCNGeometry(sources: sources, elements: [elem])
        let mat = SCNMaterial()
        if showTexture, let tex = blended.albedo { mat.diffuse.contents = tex } else { mat.diffuse.contents = UIColor.systemTeal }
        mat.isDoubleSided = false
        mat.lightingModel = .phong
        mat.fillMode = showWireframe ? .lines : .fill
        geo.firstMaterial = mat
        node.geometry = geo
        scene.rootNode.addChildNode(node)
        // Auto-fit camera based on mesh radius
        let radius = (vertsMeters.map { sqrt($0.x*$0.x + $0.y*$0.y + $0.z*$0.z) }.max() ?? 0.1)
        let cam = SCNCamera(); cam.zFar = 100; cam.zNear = 0.001
        let camNode = SCNNode(); camNode.camera = cam; camNode.position = SCNVector3(0, 0, radius * 3)
        scene.rootNode.addChildNode(camNode)
        let light = SCNLight(); light.type = .omni; let ln = SCNNode(); ln.light = light; ln.position = SCNVector3(0,0,0.6); scene.rootNode.addChildNode(ln)
        return scene
    }
}


