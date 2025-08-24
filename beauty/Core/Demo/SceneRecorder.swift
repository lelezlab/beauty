import Foundation
import SceneKit
import AVFoundation
import UIKit

@MainActor
enum SceneRecorder {
    static func record(mesh: FaceMesh3D, duration: TimeInterval, output: URL) async throws {
        let size = CGSize(width: 960, height: 540)
        let scene = SCNScene()
        let node = SCNNode()
        let verts = mesh.vertices.map { v -> SCNVector3 in
            let m = Units.mmToMeters(v)
            return SCNVector3(m.x, m.y, m.z)
        }
        let vsrc = SCNGeometrySource(vertices: verts)
        var sources: [SCNGeometrySource] = [vsrc]
        if let uvs = mesh.uvs {
            let uv = uvs.map { CGPoint(x: CGFloat($0.x), y: CGFloat(1 - $0.y)) }
            sources.append(SCNGeometrySource(textureCoordinates: uv))
        }
        let idx: [UInt32] = (mesh.indices ?? mesh.faces).flatMap { [$0.x, $0.y, $0.z] }
        let data = Data(bytes: idx, count: idx.count * MemoryLayout<UInt32>.size)
        let elem = SCNGeometryElement(data: data, primitiveType: .triangles, primitiveCount: idx.count/3, bytesPerIndex: MemoryLayout<UInt32>.size)
        let geo = SCNGeometry(sources: sources, elements: [elem])
        let mat = SCNMaterial(); mat.diffuse.contents = mesh.albedo ?? UIColor.systemTeal; mat.isDoubleSided = false
        geo.firstMaterial = mat
        node.geometry = geo
        scene.rootNode.addChildNode(node)
        let cam = SCNCamera(); cam.zFar = 100; let camNode = SCNNode(); camNode.camera = cam; camNode.position = SCNVector3(0,0,0.5); scene.rootNode.addChildNode(camNode)
        let ln = SCNNode(); ln.light = SCNLight(); ln.light?.type = .omni; ln.position = SCNVector3(0,0,0.6); scene.rootNode.addChildNode(ln)

        let scnView = SCNView(frame: CGRect(origin: .zero, size: size))
        scnView.scene = scene
        scnView.isPlaying = true
        scnView.backgroundColor = .black
        scnView.autoenablesDefaultLighting = true

        try? FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
        let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
        let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: Int(size.width), AVVideoHeightKey: Int(size.height)]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA, kCVPixelBufferWidthKey as String: Int(size.width), kCVPixelBufferHeightKey as String: Int(size.height)])
        writer.add(input)
        writer.startWriting(); writer.startSession(atSourceTime: .zero)

        let fps: Int32 = 30
        let frameCount = Int(duration * Double(fps))
        var toggled = false
        for i in 0..<frameCount {
            while !input.isReadyForMoreMediaData { usleep(1000) }
            let t = CMTime(value: CMTimeValue(i), timescale: fps)
            // rotate
            let angle = Float(i) * (2 * .pi) / Float(frameCount)
            node.eulerAngles = SCNVector3(0, angle, 0)
            if !toggled && Double(i)/Double(frameCount) > 0.45 {
                toggled = true
                geo.firstMaterial?.fillMode = .lines
            }
            autoreleasepool {
                let img = scnView.snapshot()
                var pb: CVPixelBuffer?
                if let pool = adaptor.pixelBufferPool {
                    var px: CVPixelBuffer?
                    let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &px)
                    if status == kCVReturnSuccess, let px = px {
                        CVPixelBufferLockBaseAddress(px, [])
                        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(px), width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(px), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
                        if let cg = img.cgImage { ctx.draw(cg, in: CGRect(origin: .zero, size: size)) }
                        CVPixelBufferUnlockBaseAddress(px, [])
                        pb = px
                    }
                }
                if let pb = pb ?? pixelBuffer(from: img, size: size) { adaptor.append(pb, withPresentationTime: t) }
            }
        }
        input.markAsFinished(); writer.finishWriting {}
    }

    private static func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        var pb: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: true, kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA, attrs, &pb)
        guard status == kCVReturnSuccess, let px = pb else { return nil }
        CVPixelBufferLockBaseAddress(px, [])
        defer { CVPixelBufferUnlockBaseAddress(px, []) }
        let ctx = CGContext(data: CVPixelBufferGetBaseAddress(px), width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(px), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
        ctx.interpolationQuality = .high
        if let cg = image.cgImage { ctx.draw(cg, in: CGRect(origin: .zero, size: size)) }
        return px
    }
}


