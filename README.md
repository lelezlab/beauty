## beauty 应用页面与交互规划（iOS）

### Proof Pack 一键生成/下载（零交互版）

本地（模拟器或真机均可）：

1. 运行 App → 设置 → Proof Pack（默认自动执行 Run BOTH）
2. 完成后自动弹系统分享；在 Documents/proof/ 目录下获得（并额外打包 proof.zip）：
   - mockTrueDepth/demo.mp4、mockTrueDepth/diagnostics.png
   - triView/demo.mp4、triView/diagnostics.png
   - edge_recon/demo.mp4、edge_recon/diagnostics.png、edge_recon/last_job.json
   - proof.zip（上述文件的打包）

CI（GitHub Actions）：

1. 在 PR 面板的 Artifacts 下载 `proof-pack`（proof-pack.zip）
2. Workflow 动态选择最新可用 iPhone 模拟器，稳定产出 proof

### 零交互验收（3 行）
```
cp .env.example .env
# 修改 .env：SUPABASE_PROJECT_REF / MODEL_MIRROR_BASE / EDGE_BASE_URL
make all
```

### AI 能力栈（新增模块）

- iOS 端（可离线编译，在线可选）
  - `Core/AIProviders/FaceMeshProvider.swift`：FaceMesh 468 点占位（Vision 近似，上采样到 468）。
  - `Core/AIProviders/ORTMobile.swift`：ONNX Runtime Mobile 封装（未集成优雅降级）。
  - `Core/AIProviders/ArcFaceEmbedder.swift`：ArcFace 本地 ORT/远端/Stub 三段式。
  - `Core/AIProviders/FaceParsingClient.swift`：分割远端占位；`DepthClient.swift`：MiDaS 深度占位。
  - `Core/Texture/SeamlessBlender.swift`：OpenCV seamlessClone 的 CoreImage 兜底实现。
  - `Features/CelebMatch/CelebMatchView.swift`：相似度 Top-K UI。
- 重建回退链路
  - `ReconstructionOrchestrator`：ARKit → Edge → 3DDFA_V2（新）。
  - `Core/Reconstruction/ThreeDDFAReconstruction.swift`：对接 `ThreeDDFAURL`。

### 黄金比例面罩与毫米热力（How to）

- 2D/3D 黄金面罩资源位于 `specs/golden_mask/`（OBJ/anchors）。
- 在 3D 预览页（`Face3DPreviewView`）中：
  - 叠加 `GoldenMask3DOverlay(mesh:t1:t2:alpha:)`，可实时调节：
    - 绿≤t1（mm）、黄≤t2（mm）、透明度 alpha、术前/术后对比滑杆。
  - `GoldenMaskAlignment3D` 对黄金面罩与用户网格做相似变换并输出每顶点偏差→颜色（±1mm 绿，±3mm 黄，>±3mm 红）。

### 全面面部测试分析（规划）

- 扩充 `AestheticsMetrics` 覆盖眼鼻唇颌：角度/长度/宽高比/曲率等；输出风格词与“差异热点”。
- 解剖联动：`AnatomyView` 高亮组织，术式滑杆与软/硬边界绑定。
- 术后 3D 模拟：TPS + Multi‑view consistency；Before/After 对比与 3D 截屏。


### 服务端骨架（stubs）

- `server/services/3ddfa_v2/app.py`：/ai/3ddfa/recon 返回占位网格
- `server/services/face_parsing/app.py`：/ai/face-parsing 返回占位 mask
- `server/services/midas_depth/app.py`：/ai/midas/depth 返回占位 depth
- `server/services/arcface_embed/app.py`：/ai/arcface/embed 返回占位 embedding
- `server/utils/open3d_tools.py`：法线/平滑占位；无 open3d 时降级
- `supabase/sql/celeb_gallery.sql`：明星图库 + pgvector 索引

### 端点配置（Info.plist）

在应用的 Info.plist 中可选设置以下键以启用远端：
- `ThreeDDFAURL`、`ArcFaceEmbedURL`、`FaceParsingURL`、`MiDaSDepthURL`
未配置时自动降级到本地/占位逻辑。

本文件用于追踪页面结构、交互设计与实现进度，覆盖从引导拍摄到美学分析、预设预览与手动编辑的核心流程。

## 导航结构

- 主入口: `beautyApp` → `MainTabView`
- Tab 重构（对齐你给的主页面能力，保留原功能为二级页）：
  - 首页 Home（引导拍摄 + 商城精选入口 + 快捷功能合集）
  - 商品 Mall（推荐/补贴/上榜/会员卡 等商品分发）
  - 案例 Cases（项目/部位维度浏览真实案例，含前后对比/搜索/筛选）
  - 机构 Clinics（医院/机构榜单、地图/附近、详情）
  - 医生 Doctors（医生库、专长与评价、预约入口）
  - 我的 Me（账号、订单、消息、历史会话、设置、隐私）

## 页面明细与交互

### 1. Onboarding / 权限页（首启可选）
- 目标：解释应用用途与隐私，请求相机权限
- 关键交互：
  - 展示用途说明与示例图
  - 按钮「开启相机权限」→ 弹系统权限框
  - 权限被拒：展示「去设置」按钮
- 状态/异常：权限未授权、用户退出

### 2. Home（首页）
- 目标：一键开始拍摄 + 商城精选 + 快捷功能聚合
- 顶部：
  - 城市选择（定位/切换）
  - 搜索框（项目/机构/医生/商品），右侧「AI 助手｜深度医美思考·快速专业分析」入口
  - 购物车入口（角标）
- Banner：主运营位轮播（优惠/补贴/活动）
- 九宫格分类（示例）：皮肤管理、除皱抗衰、瘦脸轮廓、鼻部、美体塑形、玻尿酸、眼部、私密整形、嗨Buy 指南
- 精选区块：
  - 风向标（趋势/必看内容 → 文章/专题/短视频）
  - 超级补贴（全城底价比，直达商品列表）
  - 吸脂名院（机构精选榜，直达机构详情）
- 快捷功能：口碑榜、魔镜（AR/AI 试脸）、试用官、美肤套餐、附近优惠、福利社
- 交互：
  - 开始拍摄（Sheet/全屏）
  - 若已有 front 照片，展示「查看分析」跳转 `AnalysisView`

### 3. GuidedCaptureView（引导拍摄）
- 目标：按顺序采集 正面 / 左侧 / 右侧 三张高质量照片
- 组成：
  - 相机实时预览（`CameraSession`）
  - 质量提示：光线不足、画面模糊
  - 水平仪（滚转角）
  - 步骤指示：step 0/1/2，提示当前角度与动作
  - 控件：拍照、重拍、完成
- 交互细节：
  - 拍照：抓取最新 frame → 写入当前步骤图片 → 自动进入下一步
  - 重拍：清空当前步骤图片
  - 完成：三图齐全时启用，回传到上级或直接跳 `AnalysisView`
- 错误处理：
  - 相机不可用：提示并引导至设置
  - 质量过低：按钮仍可用，但展示二级提示

### 4. AnalysisView（美学分析）
- 目标：基于 `Vision` 关键点输出核心指标与可视化
- 内容：
  - 原图展示
  - 指标区：
    - 三庭综合比、五眼比例、鼻唇角、下巴投影、宽高比等
  - 预设区：`StylePreset` 横向列表 → 进入预览
- 交互：
  - 进入即异步 `FaceAnalyzer.detectLandmarks`
  - 计算指标：`MetricsCalculator.compute`
  - 点选预设 → `PresetPreviewView` 或编辑页
- 状态：加载中/失败重试；无法检测到人脸的提示

### 5. PresetPreviewView（一键预设预览）
- 目标：快速查看不同风格模板的效果对比
- 组成：
  - 渲染器 `MorphingRenderer.applyPreset` 输出预览图
  - 操作：对比开关（原图/效果）、导出/保存、去手动编辑

### 6. ManualEditView（手动编辑）
- 目标：对关键区域进行细调（鼻尖、下巴、眼距等）
- 组成：
  - 画布：原图 + 叠加可调控点/网格
  - 调整项：滑杆/步进器/开关
  - 撤销/重做、重置、保存
- 交互：
  - 拖拽控制点 → 实时预览
  - 保存写入 `BeautySession.editedImageData`

### 7. 商品 Mall（新增）
- 顶部分段：为你推荐、超级补贴、上榜商品、小绿卡（会员）、塑形修复、附近好价、福利社
- 列表：卡片含主图/项目/机构标签/到手价/券标/销量
- 商品详情：图文/参数/适应人群/注意事项/机构/医生/到院须知
- 购物车：加入/修改/删除；下单占位（后续接入支付或到店核销）

### 8. 案例 Cases（新增）
- 维度：项目/部位/难度/价格区间/城市
- 卡片：前后对比、术式标签、机构与医生、恢复时间
- 详情：图集、步骤、感受、风险/副作用说明、同类推荐

### 9. 机构 Clinics（新增）
- 列表：综合排序/距离/口碑/价格；地图与列表切换
- 榜单：TOP 机构、名院专栏
- 详情：项目价格、医生团队、环境、评价、路线/停车

### 10. 医生 Doctors（新增）
- 列表：执业年限、专长、案例数、评分、所在机构
- 详情：资质/擅长案例/价格区间/可预约档期

### 11. 我的 Me（整合原 History/Settings）
- 入口：我的订单、购物车、消息、历史会话（原 History）、账号与隐私（原 Settings）
- 会员：小绿卡权益、优惠券
- 资料：实名认证（可选）、收货/到诊信息

### 12. History（历史会话，迁入「我的」）
- 目标：管理本地的 `BeautySession`
- 组成：
  - 列表卡片：缩略图、时间、指标摘要
  - 搜索/筛选（时间区间、是否已编辑）
- 交互：
  - 点开进入详情（复用 `AnalysisView` + 预设/编辑入口）
  - 左滑删除（确认框）

### 13. Settings（设置，迁入「我的」）
- 目标：账户与订阅占位、隐私与调试
- 条目建议：
  - 登录/登出（占位）
  - 订阅与恢复购买（占位）
  - 导出/清除本地数据
  - 隐私说明、开源许可
  - 调试开关（日志、质量阈值）

### 14. AI 助手（顶部入口 + 多处召回）
- 模式：问答/引导购/方案咨询，与本地模拟打通（上传三视图 → 输出建议与预设）
- 交互：FAQ 模板、项目/医生/机构推荐、创建拍摄任务、跳转下单/预约
 - 标语：深度医美思考 · 快速专业分析（对齐你截图的右上角文案）

## 用户关键流程

1) 首次使用 → 权限 → 首页 → 引导拍摄（3 步）→ 分析 → 预设预览/手动编辑 → 保存/分享

2) 回访 → 历史 → 选会话 → 分析/编辑 → 导出

## 数据与状态

- BeautySession（待接入 SwiftData 持久化）：
  - id、createdAt
  - front/left/right 原图 Data
  - analysisJSON（关键点/指标缓存）
  - editedImageData（最终图）
- 运行态：
  - CameraSession：sampleBuffer、exposureTooLow、isBlurry、levelDegrees
  - Analysis：landmarks、metrics、loading 状态

## 可交互原型（当前实现状态）

- [x] Home → 引导拍摄 → 分析 → 预设预览
- [x] 质量提示/水平仪
- [x] 基础指标计算
- [ ] 顶部导航（城市/搜索/AI 助手/购物车）
- [ ] Banner 轮播与九宫格分类
- [ ] 运营区块：风向标/超级补贴/吸脂名院
- [ ] 快捷功能：口碑榜/魔镜/试用官/美肤套餐/附近优惠/福利社
- [ ] ManualEdit 交互细化（拖拽控制点/撤销重做）
- [ ] SwiftData 持久化接入（iOS 17+）
- [ ] 分享/导出
- [ ] 登录/订阅（占位转实现）

## 开发状态跟踪（可执行清单）

状态说明：✅ 已完成｜🟡 进行中｜📝 计划中｜⛔ 阻塞

- 核心能力
  - ✅ 相机预览/拍照/质量提示/水平仪（`CameraSession`）
  - ✅ 关键点检测与指标计算（`FaceAnalyzer`/`AestheticsMetrics`）
  - ✅ 预设渲染预览（`MorphingRenderer`）
  - 🟡 手动编辑交互（控制点/撤销重做）
  - 📝 SwiftData 持久化（会话/图片/分析 JSON）
- 首页与导航
  - ✅ Tab 与基础路由（`MainTabView`）
  - 🟡 首页骨架（Banner/九宫格/精选区块/快捷功能占位）
  - 🟡 顶部城市/搜索/购物车/「AI 助手｜深度医美思考·快速专业分析」入口
- 商城与内容
  - 📝 商品分发/详情、购物车与订单占位
  - 📝 案例库（筛选/详情）、机构榜单/地图、医生库与详情
  - 📝 会员小绿卡、优惠券/活动页
- AI 助手
  - 🟡 问答/引导购/方案咨询（与三视图/分析联动）
- 我的/设置
  - 🟡 历史会话迁入、消息/订单/设置聚合
- 工程化
  - ✅ main 分支保护
  - 📝 CI（构建/测试/SwiftLint）、崩溃/日志上报

## 研发路线图 / 任务清单

- 摄像头与引导
  - [x] 实时预览与抓拍
  - [x] 水平仪、光线/模糊评估
  - [ ] 网格/脸部对齐辅助线
- 分析与指标
  - [x] Vision 关键点检测
  - [x] 三庭五眼/鼻唇角/宽高比
  - [ ] 更多面部比例/角度（额头、颧弓、下颌角）
- 渲染与编辑
  - [x] 预设渲染（轻量）
  - [ ] 高精度形变（局部网格 + 约束）
  - [ ] 手动编辑工具组与历史记录
- 数据与同步
  - [ ] SwiftData 本地存储
  - [ ] iCloud 同步（可选）
- 产品化
  - [x] Git 分支策略与保护（main 已启用）
  - [ ] CI：构建/测试/SwiftLint
  - [ ] 崩溃/日志上报（可选）
 - 商城与内容
- 远程效果中心
  - 🟡 协议/清单/验签/灰度/缓存/回滚框架（EffectPack/Manifest/EffectCenter/验签/示例 UI）
  - 📝 本地兜底包、EffectComposer 接入与真实渲染
  - 📝 README_RemoteEffects 使用文档

   - [ ] 商品分发与详情、购物车与订单占位
   - [ ] 案例库（搜索/筛选/详情）
   - [ ] 机构榜单/地图、医生库与详情
   - [ ] 会员小绿卡、优惠券与活动页
   - [ ] AI 助手（问答/引导购/拍摄联动）

## 设计约束与规范

- 平台：iOS 17.0+
- 视觉：浅色优先，后续补深色模式适配
- 性能：预览/渲染在后台队列，UI 主线程回调
- 隐私：仅本地处理；分享/导出需二次确认

## 变更记录（开发节奏快照）

- 2025-08-19
  - 修复 Git/SSH，合并 `feat/mvp-bootstrap` 至 `main`，删除旧分支
  - 新增 `.gitignore` 与主功能代码；启用 `main` 分支保护
  - 修复构建问题（Info.plist 冲突、依赖导入、iOS 17 部署、CoreMotion 队列）
  - 预览可编译；模拟器运行通过；相机 API 弃用项已处理


## 产品定位与错位打法（补充）

- 定位：个人的术前决策助理（私密拍照 → 质检 → 测量 → 模拟 → 风险/预算建议 → 咨询材料导出），而非导流型平台
- 价值主张：
  - 真：多视角拍摄 + 质检 + 客观美学指标（非滤镜“变美”）
  - 准：关键点/比例/角度的数字化评估（可溯源）
  - 安：本地推理与本地存储，默认不上云，支持一键彻底删除
- 商业化路径：先 C 端订阅（高级模板、报告导出、3D 预研包），再开放 B 端工具（诊所/医生术前沟通）

## 核心闭环（必做 + 强化）

- 引导式三视图拍摄 + 质检（水平仪、清晰度/曝光/遮挡校验）
- 端侧 landmarks 与姿态（多角度稳定；对齐后再形变）
- 美学指标报告（三庭五眼、鼻唇角、下巴投影、宽高比等）+ 解读
- 一键模板（自然/韩系/日系/欧美），参数透明、可回退
- 手动编辑器（鼻/下巴/颌线/颧/唇滑杆；左右分屏对比）
- 导出：对比图（水印/免责声明）+ 咨询 PDF（指标、术式要点、预算区间、问题清单）
- 知识库：术式原理、禁忌、流程、风险与护理（面向决策质量）

## 差异化能力（与平台拉开档位）

- 多视角一致性引擎：正/侧/斜三图联动形变，避免“正面好看、侧面崩”
- 可信度仪表：结合拍摄/姿态/遮挡/光照给出可信度刻度；对用户设预期
- 安全阈值与红线提醒：编辑参数限制在医学安全区间，超阈橙/红预警
- BDD 自评与心理守护：提供自评问卷与专业求助链接（合规与社会责任）
- 隐私默认开启：本地保存，云端需二次同意；支持一键彻底删除与局部加密备份
- 医生沟通友好：PDF 自动生成“问题清单 + 术后护理清单 + 风险提示”
- 模板来源与风格指纹：注明风格来源与参数区间，提升可信
- 多人协同标注：支持朋友/医生在导出 PDF 上批注，形成“术前共识”
- B 端 SDK（预研）：诊所 iPad 可用测量/模拟能力在院内演示

## 关键功能路线（新增）

- 多视图联动模拟（正/侧/斜一致形变）
- 可信度刻度 + 质检评分（把“好不好拍、可不可信”说清楚）
- 指标溯源解释（每个指标的点位/公式/影响权重）
- 参数安全阈值/红线提醒（避免激进拉扯）
- 咨询 PDF 一键导出（对比图、指标、问题清单、免责声明、预算提示）
- BDD 自评与心理健康链接
- 本地优先 + 数据主权（默认不上云、加密备份、可清除）
- 模板来源声明与风格指纹
- 多人协同标注与批注
- B 端 SDK 预研

## 开发状态追踪（增补）

状态：✅ 已完成｜🟡 进行中｜📝 计划中

- 拍摄 & 质检
  - ✅ 水平仪、光照/清晰度质检、十字引导、正/侧遮罩
  - 🟡 对齐评分（角度/中心偏移/占比，实时进度条）
  - 📝 三视图一致性对齐（联动评分）

- 分析 & 可视化
  - ✅ Landmarks 叠加、核心指标条形图、雷达图（示意）
  - 🟡 指标分级与预警（绿/橙/红）
  - 📝 指标溯源解释（点位/公式/权重）

- 建议引擎 & 知识库
  - ✅ 基础建议引擎（比例/角度/投影/宽高比）
  - 🟡 知识库结构与本地内容扩充，分析→知识联动
  - 📝 远端知识库拉取与缓存

- 模拟 & 编辑
  - ✅ 一键模板（轻量 2D 形变）
  - 🟡 手动编辑滑杆组完善 + 撤销/重做
  - 📝 三视图联动形变（一致性）

### 新增：重建管线（Photo/Video → 3D）

- 入口与模块
  - `Core/Reconstruction/`：`ReconstructionProvider` 协议、`CaptureBundle`（front/left/right、归一化 landmarks+IPD、相机参数、QC）、`FaceMesh3D`
  - Provider：`ARKitReconstruction`（真机优先）、`DECAEdgeReconstruction`（占位回退）、`StubReconstructionProvider`（模拟器）
  - `ReconstructionOrchestrator`：从 `CaptureStore` 组包 → 调用 Provider → 写回 `CaptureStore.lastMesh`，并贯通 `CalibrationManager.scaleMMPerPixel`
- 调用位置
  - `MainTabView/CaptureModeSwitcher`：三帧完成且 QC≥0.5 自动触发 `reconstruct(.arkit)`；否则保持 2D 流程
- 依赖与降级
  - `#if canImport(ARKit)` 自动选择；无 ARKit/模拟器使用 Stub，流程完整但返回空/简化网格
- 本地运行
  - 模拟器：可编译运行（走 Stub）；真机：启用 ARKit Provider

### 新增：黄金比例面罩（2D/3D）

- `Core/GoldenMask/MaskDeviationAnalyzer`：基于 landmarks 与 IPD 的简化偏差（毫米）
- `Features/GoldenMask/GoldenMask2DOverlay`：2D 线框与偏差点（±1mm 绿/±3mm 黄/>±3mm 红）
- `Features/GoldenMask/GoldenMask3DOverlay`：SceneKit 占位（后续接真实网格）
- 接入：`EffectsGalleryView` 单图预览在开启“叠加黄金比例面罩”时启用 2D Overlay

### 新增：术式库 → 参数映射 → 解剖联动

- `Features/Effects/surgery_catalog.json`：术式 → 参数区间/关联规则/解剖结构
- `Core/Procedures/SurgeryPlanner`：读取术式并映射到 `Effects` 控件值，按 `AestheticsSafetyConfig` 裁剪
- `Features/Anatomy/AnatomyStore`/`AnatomyView`：展示对应解剖结构简介，Effects 详情里可一键打开

### 新增：细项分析与“差异热点”

- `AestheticsInsights`：
  - `styleWords(from:)` 输出风格词（例：窄长脸/上翘鼻尖/下巴后缩）
  - `hotspots(from:)` 基于黄金面罩偏差输出 Top5 热点
- `AnalysisView` 中展示风格词与热点列表

### 新增：术后像谁（离线 Demo）

- 完全离线，不引入闭源/外部服务；用户自带授权图库（zip 解压后的目录）
- 入口：`EffectsGalleryView` 预览下方 → “术后像谁（离线）”
- 目录结构示例：
  - `my_celeb/`
    - `images/` 放若干 jpg/png（如 `a.jpg`）
    - `names.csv`（UTF-8，无 BOM）：第一行头 `id,name,filename`；示例：
      - `1,张三,a.jpg`
      - `2,John Doe,b.jpg`
- 构建与匹配流程：
  - 选择解压后的 `my_celeb` 路径 → 构建索引 → 对当前术后图做 Top3 匹配
- 实现文件：
  - `Core/CelebMatch/EmbeddingModel.swift`（占位嵌入，16×8 灰度向量 L2 归一）
  - `Core/CelebMatch/EmbedIndex.swift`（索引构建 + 余弦相似度）
  - `Features/CelebMatch/CelebMatchView.swift`（UI）

- 导出 & 咨询
  - ✅ 前后对比图 + PDF（水印/免责声明）
  - 🟡 导出样式（LOGO/时间戳/定位/多版式）与一键分享
  - 📝 咨询 PDF（问题清单/护理清单/预算区间）

- 隐私与合规
  - ✅ 本地推理与本地存储默认开启；一键清除（设计）
  - 🟡 合规与底线页面（免责声明、数据最小化、撤回/删除、广告合规）
  - 📝 差分隐私/局部加密备份/数据导出
  - 📝 BDD 自评与求助链接

- 多语言 & 全球化
  - ✅ 语言切换页（中/英/法基础）；全球定位（国家/州/城市）
  - 🟡 多语言全量覆盖（核心文案与格式化）

- AI 助手（可选）
  - 📝 文本问答（仅上传指标，不上传人脸）+ 知识库检索（RAG）

## 里程碑

- M1 对齐评分与导出样式（当前冲刺）
- M2 知识库扩充与远端拉取预留
- M3 多语言全量覆盖
- M4 多视图联动与可信度仪表
- M5 咨询 PDF 强化（问题/护理/预算）
- M6 BDD 自评与隐私工具集
- M7 模板来源声明与风格指纹、协同标注
- M8 SDK 预研（B 端）


