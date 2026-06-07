# v3.9 本地工作区存储与记忆生命周期

v3.9 为 Core 输出增加本地优先的工作区管理层。在保持现有知识包输出兼容的前提下，按需生成注册表、存储报告、记忆生命周期合同，以及本地文档解析和 token 降低报告。

## 能力范围

- 本地工作区注册表，并细分 package、skill、agent、memory、document、index 注册表。
- 按资产类型统计文件数量和字节大小的存储报告。
- SHA-256 内容 hash 跟踪与重复资产建议。
- 仅建议性质的清理、归档和保留计划。v3.9 默认不删除文件。
- 记忆生命周期合同，覆盖 `session_log`、`short_term_memory`、`summary_memory`、`long_term_memory`、`memory_candidates`、`memory_index`、`retention_policy`、`compaction_policy`、`token_budget_policy`。
- 防止全历史注入的 token budget policy，优先使用 summary、long-term 和 index 引用。
- 本地 PDF 转 Markdown 预处理路径、解析后端选择、解析后端 benchmark、PDF token 降低估算和 no-cloud-upload 报告。

## 本地文档解析与 Token 降低

默认不应把原始 PDF 整体发送给 LLM。v3.9 优先采用本地解析，将文档转换为结构化 Markdown/报告输出，再进入 chunking 与 retrieval。LiteDoc 只作为隐私边界和 token 成本模式的 benchmark 吸收，不集成或复制 LiteDoc 代码。

解析路由是确定性的：

- 文本 PDF / 简单文档：轻量本地解析路径。
- 扫描件 / 图片 PDF：标记为需要 OCR。
- 复杂布局 / 表格 / 公式文档：标记为复杂解析器路径或需要人工复核。
- 未知输入：fallback 并标记 review-required。

## 不上传云端

v3.9 不上传文档、不调用云文档 API、测试不需要真实 LLM/API/网络。未来的 `local_db` 和 `byo_cloud` 后端只保留为合同占位。

## CLI

- `init-workspace`
- `scan-workspace`
- `report-storage`
- `plan-cleanup`
- `plan-memory-lifecycle`
- `estimate-token-budget`
- `preprocess-pdf-markdown`
- `benchmark-parser-backends`
- `report-pdf-token-reduction`

## 报告

关键输出包括 `workspace_registry.json`、各类注册表、`storage_usage_report.json`、`dedup_report.json`、`cleanup_plan.json`、`memory_lifecycle_report.json`、`memory_compaction_plan.json`、`token_budget_policy.json`、`local_pdf_markdown_report.json`、`parser_backend_benchmark_report.json`、`pdf_token_reduction_report.json`、`no_cloud_upload_report.json`、`v39_external_absorption_map.json`。
