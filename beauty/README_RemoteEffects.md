# Remote Effect Center

本模块允许不发版上新“变美技术”。包含：协议（EffectPack JSON）、清单（Manifest）、验签、缓存、灰度、回滚、埋点。

## 目录
- Core/RemoteEffects/
  - EffectPack.swift：数据结构（Codable）
  - SignatureVerifier.swift：P256 ECDSA 验签、SHA256
  - EffectCenter.swift：拉取清单、下载、缓存、灰度、激活、回滚
- Features/EffectsGalleryView.swift：示例 UI（清单浏览、参数滑杆、预览占位）
- Features/GoldenGuidesOverlay.swift：三庭五眼取景引导

## Manifest
```json
{"public_key_p256":"<BASE64>","effects":[{"id":"rhinoplasty_2025Q3_01","version":"1.2.0","url":"https://cdn/effects/rhino_01.json","sig":"<base64>","rollout":0.5}]}
```

## EffectPack
见 EffectPack.swift，字段同 PR 描述；assets 需提供 sha256 以做校验。

## 灰度与缓存
- rollout 命中：对 deviceId 做一致性哈希 ∈[0,1) 与 rollout 比较
- 缓存路径：`Library/Application Support/Effects/<id>/<version>/pack.json`；`current` 为符号链接指向激活版本

## 回滚
- 若渲染/崩溃率超阈值：调用 `setCurrent` 切回上一个版本，并记录 telemetry（本地 JSON）

## 本地兜底
- 在 `Effects/local/` 放 2–3 个预置包；Manifest 拉取失败时展示本地包

## 使用步骤（本地）
1. 设置 manifest URL → 点击“拉取”
2. `EffectCenter` 自动下载/验签/缓存 → `EffectsGallery` 展示列表
3. 点击某个效果 → 滑杆调参，预览占位（后续接入 EffectComposer 渲染）

## Telemetry（先落本地 JSON）
- 字段：effect_id / version / device / os / duration / share / save / crash_flag

## 法律与文案
- 所有 UI 顶部或导出处提示：仅为视觉模拟与美化，非医疗建议；未成年人提示
- pack.legal.disclaimer_id 可映射至本地文案

## 备注
- 远端失败不崩，超时可重试
- 后续可加 Tools/EffectBuilder/ 用私钥签名制作包
