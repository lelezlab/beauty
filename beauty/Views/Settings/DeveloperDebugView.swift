import SwiftUI
import UniformTypeIdentifiers

struct DeveloperDebugView: View {
    @State private var importResult: String = ""
    @State private var showImporter: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var pickedImage: UIImage?
    @State private var matches: [TopMatch] = []
    @State private var showAlignedPreview: Bool = true

    var body: some View {
        List {
            Section("Celeb Gallery") {
                Button("导入明星图库（ZIP/文件夹）") { showImporter = true }
                if !importResult.isEmpty { Text(importResult).font(.footnote).foregroundStyle(.secondary) }
                Button("选择图片进行相似度匹配") { showImagePicker = true }
                Toggle("显示对齐后头像（匹配前预处理）", isOn: $showAlignedPreview)
                ForEach(matches) { m in
                    HStack(spacing: 12) {
                        if let t = m.thumb { Image(uiImage: t).resizable().frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 6)) }
                        VStack(alignment: .leading) {
                            Text(m.name)
                            Text(String(format: "相似度 %.0f%%", m.score*100)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section("说明") {
                Text("仅用于开发验证：完全离线，不上传任何人脸特征。图库需具备授权。").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Developer (Celeb)")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [UTType.zip, .folder]) { result in
            do {
                let url = try result.get()
                Task {
                    do { try await CelebMatch.importGallery(zipURL: url); importResult = "导入完成：\(url.lastPathComponent)" }
                    catch { importResult = "导入失败：\(error.localizedDescription)" }
                }
            } catch { importResult = "选择失败：\(error.localizedDescription)" }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $pickedImage)
        }
        .onChange(of: pickedImage) { _, newVal in
            guard let img = newVal else { return }
            do { matches = try CelebMatch.match(image: img, topK: 3) } catch { importResult = "匹配失败：\(error.localizedDescription)" }
        }
    }
}

// 简易 UIKit ImagePicker 封装
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController(); p.sourceType = .photoLibrary; p.delegate = context.coordinator; return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(parent: self) }
    final class Coord: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker; init(parent: ImagePicker){ self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
            parent.image = (info[.originalImage] as? UIImage)
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController){ picker.dismiss(animated: true) }
    }
}


