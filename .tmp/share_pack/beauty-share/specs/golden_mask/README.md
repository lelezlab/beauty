# Golden Mask Specs

- 坐标与单位
  - 2D SVG：像素坐标，画布原点左上；配套 `scale_mm_per_px` 将像素换算为毫米
  - 3D OBJ：单位毫米，右手坐标系，Y 轴向上，面朝 +Z
- 锚点命名需与指标系统一致（如 `nasion`/`pronasale`/`pogonion` 等）
- 文件：
  - `golden_mask_2d_front.svg` / `golden_mask_2d_profile.svg`（可选）
  - `golden_mask_anchors.json`（锚点与曲线定义，必须）
  - `golden_mask_3d.obj`（面罩网格，占位）
  - `anchors_3d.json`（关键点索引映射，可选）

## JSON 示例字段

```
{
  "version": 1,
  "unit": "mm",
  "scale_mm_per_px": 0.25,
  "anchors": [
    {"name":"nasion","type":"point","desc":"鼻根点"},
    {"name":"pronasale","type":"point","desc":"鼻尖"},
    {"name":"pogonion","type":"point","desc":"颏前点"}
  ],
  "curves": [
    {"name":"dorsum","through":["nasion","pronasale"],"smoothing":0.2}
  ],
  "targets": [
    {"param":"tipRotationDeg","metric":"nasolabial_angle_deg_female","soft":[95,105],"hard":[90,110]}
  ]
}
```
