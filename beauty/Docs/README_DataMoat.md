# Data Moat v1（匿名结构化数据）

目标：仅上传匿名结构化数据，上不了原始人脸；形成标准化协议与埋点闭环。

## Schema（事件与表映射）
- sessions: `BTSessionEnvelope`
- captures: `BTCaptureQC`
- geometry: `BTGeomPayload`（468/ROI 归一化至 IPD，量化至 1e-3）
- metrics: `BTMetricsPayload`（三庭/五眼/鼻唇角/下巴投影/宽高比）
- effects: `BTEffectRecord`（effect_id/version/params/confidence）
- ratings: `BTRatingRecord`（realism/satisfaction/regions[]）

## 字段说明（节选）
- QC_scores: blur/exposure_mean/face_coverage/yaw/pitch/roll/focal_eq/distance_bucket/aeLocked/awbLocked
- landmarks: 以左眼中心为原点，单位=IPD，保留三位小数；差分隐私：Laplace(epsilon)
- metrics: 同上，角度以度表示

## 合规与隐私
- 默认不上原图；“研究计划”需二次弹窗同意，可随时撤回并删除
- 差分隐私默认开启（epsilon 可配），仅影响上传前的数据；本地功能不受影响
- 所有上传走 HTTPS；提供数据导出/删除入口

## 上传接口
- `TelemetryUploader` 协议 + `URLTelemetryUploader(endpoint)` 实现
- 内容类型：application/jsonl；一行一个事件（BTEvent）

## 阈值建议
- 采集质量：blur<阈、exposure_mean∈区间、face_coverage>阈；姿态 |yaw/pitch/roll|<阈
- 距离：distance_bucket 2–4 视图最佳

## 版本策略
- Schema 以 `x.y` 标注；破坏性更改升级主版本
- 客户端带上 `app_version` 与 `schema_version`

## 本地调试与导出
- App 设置 → 隐私与数据 → 填写 Endpoint（可用本机或 `http://localhost:8787/ingest`）
- 导出本地样本（JSONL）或清空
