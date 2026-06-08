# HeiTang KB Forge Skill

[English](README.md) | 中文说明

当前 Core 版本：`3.12.0-alpha.1`

HeiTang KB Forge 是一个 offline-first、local-first 的 Core Skill，用于构建 Agent-ready knowledge package。它把本地资料转成标准化、可追溯、可检索、可审计、可复用的知识资产，可服务于 RAG、文档生成、Skill package 和本地 Agent workflow。

## 当前状态

最新 Core P0 证明已经完成 Core pre-v4 RC readiness：

- 最新 Core P0 证明：`docs/audits/local_acceptance/pre_v4_p0_after_live_llm`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- 剩余 Core P0：最新 pre-v4 P0 证明中无剩余 Core P0。
- 本轮文档治理前的基线证据：Core main `053a6a6`，GitHub CI run `27140288050` success。

v4.0 仍未开始、未发布、未打 tag。v4.0 尚未发布。UI full-operation 仍然 blocked，因此本仓库不能声明完整用户可操作 Workbench。

当前真值入口：[当前真值](docs/00_overview/CURRENT_TRUTH.zh-CN.md) 和 [最终产品架构真值](docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md)。

## Core 能力

- Markdown、TXT、DOCX、文本 PDF、图片/OCR 路由、CSV/TSV/XLSX、HTML、EPUB、ZIP 和多源混合输入的本地 ingestion。
- 标准 package 输出：`manifest.json`、`chunks.jsonl`、`cards.jsonl`、`qa_pairs.jsonl`、`glossary.jsonl`、`quality_report.json`、`ingest_report.md`。
- 确定性 query rewrite、retrieval planning、本地索引、本地 JSON vector query、hybrid retrieval、rerank、evidence selection 和 knowledge accuracy reports。
- Grounded Markdown、DOCX、PDF、PPTX 文档生成。
- 面向 Codex、Claude Code、OpenClaw 和通用本地 Agent integration 的 Skill-first Agent package 表面。
- 本地 mother/child Agent runtime smoke、KB boundary 检查、memory policy reports、workspace storage、lifecycle reports 和 release hardening gates。
- no hidden upload、secret redaction、no platform-hosted user data 和 optional provider boundary 的本地隐私安全报告。

完整列表见 [能力矩阵](docs/00_overview/CAPABILITY_MATRIX.zh-CN.md)。Parser backend 定位见 [Parser Backend Strategy](docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md)。

## 快速开始

安装本地开发包：

```powershell
python -m pip install -e ".[dev]"
```

可选本地 parser extras：

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,web]"
```

构建并检查本地知识包：

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart_output
python -m heitang_kb_forge.cli check-contract --package .\tmp_quickstart_output --output .\tmp_contract
python -m heitang_kb_forge.cli kb-index --package .\tmp_quickstart_output --output .\tmp_kb_index
python -m heitang_kb_forge.cli kb-query --package .\tmp_quickstart_output --query "Summarize the package" --output .\tmp_kb_query
python -m heitang_kb_forge.cli generate-documents --package .\tmp_quickstart_output --output .\tmp_documents
```

有完整证据输入时运行严格 final pre-v4 Core audit：

```powershell
python -m heitang_kb_forge.cli final-pre-v4-audit --core-repo . --output .\tmp_final_audit
```

## 文档

唯一主文档入口是 [文档索引](docs/DOCS_INDEX.zh-CN.md)。请从这里进入：

- 当前真值与发布状态
- 能力矩阵
- P1 UI Core Parity 与 P2 Productization 路线
- 命令参考、用户手册、故障排查、架构、隐私文档
- 根目录 report/audit/gate 证据策略

常用入口：

- [当前真值](docs/00_overview/CURRENT_TRUTH.zh-CN.md)
- [能力矩阵](docs/00_overview/CAPABILITY_MATRIX.zh-CN.md)
- [Parser Backend Strategy](docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md)
- [P1 UI Core Parity](docs/10_roadmap/P1_UI_CORE_PARITY.zh-CN.md)
- [P2 Productization](docs/10_roadmap/P2_PRODUCTIZATION.zh-CN.md)
- [文档治理](docs/DOCUMENTATION_GOVERNANCE.zh-CN.md)

## 路线状态

- Core pre-v4 RC readiness：最新 Core P0 gate 已完成。
- P1 UI Core Parity：未完成；UI full-operation 仍然 blocked。
- P2 Productization：P1 UI Core Parity 有证据后再推进。
- v4.0：未开始、未发布、未打 tag。

UI 信息架构已冻结，作为规划 contract 使用，但 UI 是 presentation layer，不是 Core product engine。本 README 不声明完整 Workbench operation。

## 根目录证据表面

根目录只保留当前 gate JSON 文件。历史过程文档与旧 root reports 应回到 git history、tags 或明确范围的 audit proof 目录中。请优先使用 [文档治理](docs/DOCUMENTATION_GOVERNANCE.zh-CN.md) 和 [文档索引](docs/DOCS_INDEX.zh-CN.md)。

## 边界

HeiTang KB Forge 默认不会：

- 调用真实 LLM API
- 调用 embedding API
- 上传用户文档或生成包
- 保存真实用户 API key
- 运行外部 Agent runtime
- 启动真实 MCP server
- 提供 SaaS 多租户、团队权限、cloud sync 或 platform-hosted user data
- 在独立 UI full-operation gate 通过前，声明完整 Workbench operation 或 v4.0 release readiness

LLM 仍然只是 optional only；Core tests 不需要真实 LLM/API/network 调用。

## License

MIT License. See [LICENSE](LICENSE)。
