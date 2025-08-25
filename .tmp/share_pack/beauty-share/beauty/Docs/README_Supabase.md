## Supabase 接入指南（App 侧）

### 1) 配置密钥（不入库）
1. 打开 Supabase 项目 → Project Settings → API，复制 `Project URL` 与 `anon key`。
2. 复制 `beauty/Config/Supabase.xcconfig.sample` 为 `beauty/Config/Supabase.xcconfig`。
3. 将以下键填写到新文件：

```
SUPABASE_URL = https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY = YOUR-ANON-KEY
```

> 注意：`Supabase.xcconfig` 已加入 `.gitignore`，请勿提交真实密钥。

### 2) Xcode 工程
`Supabase.xcconfig` 已在工程 Build Settings 引用（Debug/Release 继承）。修改后无需重启即可生效。

### 3) 运行与联调
- iOS 端默认仅上传匿名结构化数据，不上传原图。
- 在“设置 → 隐私与数据”可打开/关闭上报、差分隐私、导出/删除本地数据。
- 如果后端启用 Edge Function 采集（推荐）：在“Endpoint URL”填 `https://.../functions/v1/ingest_telemetry`。
- 使用 PostgREST 直写方案：无需自建函数，App 直调 `${SUPABASE_URL}/rest/v1/{table}`，Header 包含 `apikey` 与 `Authorization: Bearer {anon}`，RLS 开启且仅允许 insert。

### 4) 安全
- 前端仅持有 `anon key`，RLS 将基于 Supabase Auth 限权；`service_role` 仅用于服务端。
- 可选：开启 HMAC 头部签名，App 与服务端共享单独的 `INGEST_HMAC_KEY`。

### 在 Supabase 中执行 SQL（init_telemetry.sql）
1. 打开 Supabase 控制台 → SQL Editor。
2. 复制 `server/supabase/sql/init_telemetry.sql` 全文粘贴执行。
3. 在 Table Editor 中检查 5 张表已创建，RLS 已开启；在 API 文档页可看到 `/rest/v1/{table}` 端点。


