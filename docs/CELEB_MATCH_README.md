# Celeb Match — 离线图库与五点对齐

- 本功能完全离线：不上传任何人脸图像/特征。图库需具备授权。
- Swift 与 Python 工具链采用同一套 5 点对齐（ArcFace 112×112 模板 + Umeyama），对齐结果应一致（像素差 < 2/255）。

## 使用

1) 准备图库（示例见 `samples/celeb_gallery/`）并解压
2) App → 设置 → Developer (Celeb)
3) 导入图库（ZIP/文件夹），完成后选择任意图片进行 Top3 匹配

## 模型

- 如需使用 ArcFace CoreML：
```
python3 tools/convert_arcface_to_coreml.py --onnx arcface.onnx --out ArcFace.mlpackage
```
将输出加入 iOS Target（mlmodelc），Swift 端会自动加载；未提供时使用 Stub 嵌入。

## Python 预构建（可选）
```
python3 tools/build_celeb_index.py --gallery_dir path/to/gallery --onnx arcface.onnx --out celeb_index
```
- 若有五点对齐 CSV：`--landmarks_csv pts5.csv`（id,x1,y1,...,x5,y5）
- 脚本会输出 `aligned_samples/` 便于人工验收。

## 五点模板（ArcFace 112×112）
- 左眼(38.2946, 51.6963)、右眼(73.5318, 51.5014)、鼻(56.0252, 71.7366)、口左(41.5493, 92.3655)、口右(70.7299, 92.2041)
- 参考实现：`Core/CelebMatch/FaceAlignment.swift`
