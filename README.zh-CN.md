# HeiTang KB Forge Skill

[English](README.md) | 中文说明

当前 Core 版本：`3.12.0-alpha.1`

当前项目阶段：pre-v4.0 industrial acceptance audit / local Workbench RC preparation。

发布状态：本地优先的 Knowledge Workbench Core 正在接近 v4.0 RC，但 v4.0 尚未发布，也没有打 tag。最终 pre-v4 门禁仍在审计产品真实性、Core/UI contract drift、安全与隐私、规模就绪、用户工作流、生成产物和文档可操作性。

HeiTang KB Forge 是一个 offline-first、local-first 知识供应链 Core Skill。它把原始资料加工为标准化、可审计、可检索的知识包，并支持确定性本地 query planning、retrieval quality 检查、knowledge accuracy 报告、grounded document generation、Skill/Agent package generation、本地 mother/child Agent runtime smoke、workspace storage 与 memory lifecycle 报告、Golden Demo acceptance 和 product hardening gates。

## 最终产品真值

当前最终门禁真值集中在 [最终产品架构真值](docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md)。

- 当前 Core P0 状态：最新 `pre_v4_p0_after_live_llm` 证明为 `ready_for_v4_rc`。
- 剩余 Core P0：最新 pre-v4 P0 证明中无剩余 Core P0。
- 阻断 P1：当前没有被接受为阻断 Core 主链的 P1。
- UI validation 当前在 dirty desktop bridge worktree 的 contract/analyze/test/build 范围内通过，但完整可操作 Workbench 仍然 blocked；v4.0 仍未开始、未发布、未打 tag。

## 已实现 Core 表面

- Markdown、TXT、DOCX、文本型 PDF、图片/OCR 路由、CSV/TSV/XLSX、HTML、EPUB、ZIP 的本地构建路径。
- 标准知识包输出：`manifest.json`、`chunks.jsonl`、`cards.jsonl`、`qa_pairs.jsonl`、`glossary.jsonl`、`quality_report.json`、`ingest_report.md`。
- v3.0 Document Generation Loop：grounded Markdown、DOCX、PDF、PPTX 导出命令和报告。
- v3.7 Query Rewrite & Retrieval Planning：确定性 normalization、rewrite、expansion、decomposition、multi-query generation，以及 answering/validation retrieval planning。
- v3.8 Retrieval Quality & Knowledge Accuracy：multi-query recall、deterministic rerank、evidence selection、retrieval diagnostics、golden query evaluation、claim/source/freshness/contradiction reports 和 external absorption map。
- v3.9 Local Workspace Storage & Memory Lifecycle：本地 registry、storage usage、dedup/cleanup/retention plans、memory lifecycle、token budget policy、本地 PDF token reduction、parser backend benchmark 和 no-cloud-upload reports。
- v3.10 Local Agent Runtime & Mother/Child Operations：确定性本地 runtime smoke、task routing、child KB boundary reports、private/shared memory policy reports 和 writeback action contracts。
- v3.11 Golden Demo Acceptance Smoke：real acceptance smoke command、sample coverage、artifact openability、compatibility 和 smoke realism reports。
- v3.12 Product Hardening & Local Release Readiness：doctor/diagnostics、command/package/workspace audits、stable error taxonomy、troubleshooting、optional dependency diagnostics、privacy boundary、installer readiness 和 v4 RC gate reports。
- Pre-v4 P0-17 Book-to-Skill Structured Skill Package Completion：结构化 `SKILL.md` package、on-demand loading manifest、source/evidence map、token budget report、Claude Code/Codex/OpenClaw installability report，以及 KB/RAG/Agent compatibility proof。
- 最终 pre-v4 审计命令：`final-pre-v4-audit`。该命令故意严格，如果 P0/P1 证据没有解决，会把产品标记为 blocked。

## 仍在最终审计中的内容

- v4.0 尚未发布。
- UI Workbench 未合入 Core，必须单独验证 contract drift 和产品真实性。
- 本地 JSON vector query、hybrid keyword/vector retrieval、metadata filtering 和 stale index diagnostics 已实现并测试；外部 vector database 仍是 future/disabled。
- BYO cloud 与 local database backend 目前只是 future-compatible contracts，不是已实现默认 storage。
- SaaS、多用户权限、platform-hosted user data、cloud sync 均不在当前范围内。
- Core 测试不需要真实 LLM/API/network 调用，这些也不是默认行为；显式配置后的 live LLM acceptance 仍是独立 P0 门禁。
- 生命周期 destructive 操作保持保守：会生成 cleanup plan，但默认不会执行破坏性清理。
- 工业级规模就绪仍在按 P0/P1/P2 明确审计。

## 本地隐私边界

默认行为是 local-first：

- 不托管平台侧用户数据
- 不隐藏上传
- 测试不需要真实 LLM/API/network
- LLM 只是可选辅助层
- provider secrets 通过环境变量引用，不写入知识包输出
- BYO cloud/database 在后续版本真正实现和测试前，只能描述为 future/optional

## UI 状态

UI prototype 位于独立仓库 `kb-forge-skill-ui` 的 `feature/workbench-ui-prototype` 分支。当前 UI worktree 有已有未提交 desktop bridge 改动，并已通过 contract/analyze/test/build 验证，但页面工作流尚未端到端接入。Core 仓库会输出 Workbench contracts，但本 README 不声明完整 UI operation 已完成。

## 安装

```powershell
python -m pip install -e ".[dev]"
```

可选本地 parser extras：

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,web]"
```

## Quickstart

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart_output
python -m heitang_kb_forge.cli check-contract --package .\tmp_quickstart_output --output .\tmp_contract
python -m heitang_kb_forge.cli kb-index --package .\tmp_quickstart_output --output .\tmp_kb_index
python -m heitang_kb_forge.cli kb-query --package .\tmp_quickstart_output --query "Summarize the package" --output .\tmp_kb_query
python -m heitang_kb_forge.cli rewrite-query --query "summarize it" --output .\tmp_query_plan
python -m heitang_kb_forge.cli plan-retrieval --query "Summarize the package" --purpose answering --package .\tmp_quickstart_output --output .\tmp_retrieval_plan
python -m heitang_kb_forge.cli generate-documents --package .\tmp_quickstart_output --output .\tmp_documents
python -m heitang_kb_forge.cli product-hardening --workspace . --package .\tmp_quickstart_output --output .\tmp_hardening --no-require-v37 --no-require-v38 --no-require-v39 --no-require-v310 --no-require-v311
python -m heitang_kb_forge.cli final-pre-v4-audit --core-repo . --output .\tmp_final_audit
```

预期 build 输出：

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `quality_report.json`
- `ingest_report.md`

## 文档导航

- [文档索引](docs/DOCS_INDEX.zh-CN.md)
- [版本矩阵](docs/VERSION_MATRIX.zh-CN.md)
- [用户手册](docs/USER_MANUAL.zh-CN.md)
- [命令参考](docs/COMMAND_REFERENCE.zh-CN.md)
- [输出报告指南](docs/OUTPUT_REPORT_GUIDE.zh-CN.md)
- [本地隐私与安全](docs/LOCAL_PRIVACY_SECURITY.zh-CN.md)
- [故障排查](docs/TROUBLESHOOTING.zh-CN.md)
- [Golden Demo 指南](docs/GOLDEN_DEMO_GUIDE.zh-CN.md)
- [最终产品架构真值](docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md)
- [架构](docs/ARCHITECTURE.zh-CN.md)
- [Knowledge Ops Guide](docs/KNOWLEDGE_OPS_GUIDE.md)
- [Agent Planning Readiness Guide](docs/AGENT_PLANNING_READINESS_GUIDE.md)
- [桌面应用指南](docs/DESKTOP_APP_GUIDE.md)
- [Workbench 终极目标](docs/WORKBENCH_FINAL_TARGET.zh-CN.md)
- [Workbench 版本计划](docs/WORKBENCH_VERSION_PLAN.zh-CN.md)

当前根目录保留的机器可读历史审计报告是有意保留的证据文件，因为现有测试和文档直接引用它们。运行最终审计后可查看 `repository_surface_audit_report.json`。

## 边界

HeiTang KB Forge 默认不会：

- 调用真实 LLM API
- 调用 embedding API
- 写入向量数据库
- 上传用户文档或生成包
- 运行外部 Agent runtime
- 启动真实 MCP server
- 保存真实用户 API key
- 提供 SaaS 多租户、团队权限、cloud sync 或 platform-hosted user data

## License

MIT License. See [LICENSE](LICENSE)。
