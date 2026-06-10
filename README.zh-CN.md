# HeiTang KB Forge Skill

一个 offline-first 的 Agent Knowledge Supply Chain Core，用来把本地资料转成标准化、可追溯、可检索、可审计、可复用的知识资产。

当前 Core：v4.1.0

状态：P2.1 Parser/OCR industrial release hardening 与 Workbench sync 之后，进入 v4.1.0 stable release candidate。

快速理解入口：
- 产品定位：[docs/CURRENT_TRUTH.md](docs/CURRENT_TRUTH.md)
- 能力矩阵：[docs/CAPABILITY_MATRIX.md](docs/CAPABILITY_MATRIX.md)
- AIGC 图书/内容生产场景：[docs/AIGC_BOOK_CONTENT_PIPELINE.md](docs/AIGC_BOOK_CONTENT_PIPELINE.md)
- P2.1 parser/OCR backend evidence：[docs/audits/p2_1_parser_ocr_backends/](docs/audits/p2_1_parser_ocr_backends/)
- 验证策略：[docs/testing/VALIDATION_STRATEGY.zh-CN.md](docs/testing/VALIDATION_STRATEGY.zh-CN.md)
- 外部 benchmark 与 post-v4 路线：[docs/roadmap/external_projects/](docs/roadmap/external_projects/)
- S/A 外部项目合同加入：[docs/roadmap/external_projects/S_A_CONTRACT_INCLUSION.zh-CN.md](docs/roadmap/external_projects/S_A_CONTRACT_INCLUSION.zh-CN.md)
- English README：[README.md](README.md)

## What this project is

HeiTang KB Forge Skill 是一个本地优先的 Agent 知识供应链 Core。它负责把本地文件、书稿、制度、运营资料、课程材料等输入，转成带证据、可追踪、可复用的 knowledge package，并继续服务于 RAG、验证、文档生成、结构化 Skill package 和本地 Agent workflow。

仓库名里保留 `Skill`，是因为项目最早从 Skill-first package surface 起步。当前 Core 已经更宽：它是 headless 的知识资产生产层，可以输出 Skill package、Agent package、reports、artifacts、indexes 和 Workbench contracts。UI 只是 presentation layer，不是 Core product engine。

## Current status

当前 Core package 版本：`4.1.0`
当前 stable release：`v4.0.0`
当前 release candidate line：`v4.1.0`

- P2.1 Parser/OCR pluggable backend runtime 已完成 v4.1.0 release hardening。
- Docling、PaddleOCR、Unstructured 是真实 opt-in 本地 runtime adapters，依赖门控，不随默认安装打包。
- 最新 P2.1 proof：`docs/audits/p2_1_parser_ocr_backends/`
- 最新 live runtime proof：`docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- 本 release 中 Unstructured 的 stable surface 是 `.md/.txt`；PDF/DOCX/image extras 属于 future hardening。
- Builtin parser 仍是默认 fallback path。
- v4.0.0 保持为未改动的历史 stable tag。
- 最终架构真值：[docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md](docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md)
- `ready_for_v4_rc=true` 保留为历史 P1 evidence；v4.1.0 只增加 P2.1 parser/OCR release hardening，不启动 P2.2。

## Core capabilities

- 本地导入 Markdown、TXT、DOCX、文本 PDF、图片/OCR 路由、CSV/TSV/XLSX、HTML、EPUB、ZIP 和多源混合材料。
- 标准 knowledge package 输出：`manifest.json`、`chunks.jsonl`、`cards.jsonl`、`qa_pairs.jsonl`、`glossary.jsonl`、`quality_report.json`、`ingest_report.md`。
- 确定性 query rewrite、retrieval planning、本地索引、本地 JSON vector query、hybrid retrieval、rerank、evidence selection 和 knowledge accuracy reports。
- 面向回答和验证两种目的的 RAG 路径，包括 claim verification、contradiction detection、freshness check 和 no-answer evidence handling。
- Grounded Markdown、DOCX、PDF、PPTX 文档生成。
- 面向 Codex、Claude Code、OpenClaw 和通用本地 Agent integration 的 Skill-first package generation。
- Standalone / KB-bound Agent package surface、本地 runtime smoke、KB boundary 检查、memory policy reports 和 mother/child orchestration contracts。
- 本地 workspace registry、storage reports、lifecycle plans、artifact registries 和 P1 Workbench contract pack。
- Parser/OCR backend runtime registry、matrix、inspect、smoke、live acceptance replay，以及 Docling、PaddleOCR、Unstructured 的 opt-in adapter release evidence。
- no hidden upload、secret redaction、optional provider boundary 和 local-first operation 的隐私安全报告。

## Quick start

安装本地开发包：

```powershell
python -m pip install -e ".[dev]"
```

可选本地 parser extras：

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,parser-paddleocr,parser-unstructured,web]"
```

构建并检查本地知识包：

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
python -m heitang_kb_forge.cli parser-backend-registry --output .\tmp_parser_registry
python -m heitang_kb_forge.cli parser-backend-matrix --output .\tmp_parser_matrix
python -m heitang_kb_forge.cli parser-backend-smoke --backend builtin --output .\tmp_parser_builtin_smoke
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart_output
python -m heitang_kb_forge.cli check-contract --package .\tmp_quickstart_output --output .\tmp_contract
python -m heitang_kb_forge.cli kb-index --package .\tmp_quickstart_output --output .\tmp_kb_index
python -m heitang_kb_forge.cli kb-query --package .\tmp_quickstart_output --query "Summarize the package" --output .\tmp_kb_query
python -m heitang_kb_forge.cli generate-documents --package .\tmp_quickstart_output --output .\tmp_documents
```

在具备完整证据输入时运行严格 final pre-v4 Core audit：

```powershell
python -m heitang_kb_forge.cli final-pre-v4-audit --core-repo . --output .\tmp_final_audit
```

## Scenario entry points

**Agent Knowledge Base**

把本地资料构建成 Agent-ready knowledge package，包含可追踪 chunks、cards、glossary、QA pairs 和 quality reports。通常从 `build` 开始，用 `check-contract` 验证，再进入 Skill 或 Agent package generation。

**RAG / Verification**

使用确定性的 query planning、本地 retrieval、hybrid ranking、evidence selection、claim verification、contradiction detection 和 freshness check。Core 会区分 answering retrieval 与 validation retrieval，让报告说明答案为什么可被证据支持，或为什么应该被阻断。

**Structured Skill Factory**

从图书或知识包生成结构化 Skill package，包含 `SKILL.md`、manifests、prompts、test-prompts、token-budget reports、installability checks，以及面向 Codex、Claude Code、OpenClaw 和本地 integration 的 runtime profile guidance。

**AIGC Book Content Pipeline**

把资料库、编辑说明、书稿、制度文件和参考材料转成 AIGC 内容生产资产：package inventory、RAG verification、structured Skill outputs、Agent packages、evidence appendix，以及 Markdown/DOCX/PDF/PPTX 文档输出。见 [docs/AIGC_BOOK_CONTENT_PIPELINE.md](docs/AIGC_BOOK_CONTENT_PIPELINE.md)。

**Local Workbench**

Core 会输出 Workbench contracts、registries、schemas、deterministic fixtures、dry-run actions、smoke checks、reports 和 artifact metadata，用于本地 desktop Workbench。P1-RWF-V2 evidence 与 UI consumption pass 已复验到 `ready_for_v4_rc=true`。
UI 信息架构已冻结，继续作为 planning contract 使用，UI 仍然只是 presentation layer。

## Repository status / honesty boundary

- 本仓库只处理 Core；视觉 UI 不属于本次 Core pass。
- P1 local Workbench gate、rc.1 acceptance 与 release hardening evidence 作为 v4.0.0 历史 release proof 保留。
- 历史 P1 evidence 中仍可能保留 `not_v4_0_workbench_rc=true`，作为 stable release 之前的时间点边界。
- OpenDataLoader 和 MinerU 仍只是 external backend candidates / planned adapters。
- Docling、PaddleOCR 和 Unstructured 作为 opt-in 本地 parser/OCR runtime adapters 实现；它们依赖本地安装，不打包进 Core，不是默认 parser 路径，也不是 static Workbench 可执行外部项目。
- P2.1 live acceptance 验证 Docling 的 Markdown/TXT 样本、PaddleOCR 的 PNG OCR 样本，以及 Unstructured 的 `.md/.txt`；更广 surface 由 [backend capability boundaries](docs/audits/p2_1_parser_ocr_backends/backend_capability_boundaries.md) 明确限制。
- S/A 外部项目只进入 contract、matrix、provider boundary 和 UI visibility；这不代表功能实现。
- 依赖外部 provider、secret、network 的 actions 需要显式用户配置，且不计为 real-local passed。
- External GitHub benchmark implementation 属于 post-v4，不属于本 gate。
- Core tests 不要求真实 LLM/API/network 调用。
- Core 不保存真实用户 API key、raw private input、本地 provider profile 或本地 config outputs。
- Core 不声明 SaaS multi-tenancy、team permissions、cloud sync 或 platform-hosted user data。

规范文档入口是 [docs/DOCS_INDEX.zh-CN.md](docs/DOCS_INDEX.zh-CN.md)。GitHub About 建议文案见 [docs/GITHUB_PROFILE_COPY.md](docs/GITHUB_PROFILE_COPY.md)。

## License

MIT License. See [LICENSE](LICENSE)。
