# HeiTang KB Forge Skill

[English](README.md) | 中文说明

当前版本：`2.9.0-alpha.1`

发布状态：alpha Knowledge Runtime Loop checkpoint。当前不是 stable release。

HeiTang KB Forge 是一个 offline-first、可被 Agent 调用的知识供应链前置 Skill。它把多格式原始资料加工成标准化、可审计、可复核、可检索的知识资产包，用于 Agent 和 RAG 工作流。

项目重点是内容可靠性、准确性、证据边界、可复核性，以及 mock/live 边界清晰。

## 能力状态

Stable 本地能力：

- Markdown / TXT / DOCX / 文本型 PDF build
- 标准 7 文件知识包输出
- manifest、chunks、cards、QA、glossary、ingest report、quality report
- Contract v2 检查
- 基础 batch build
- lifecycle check
- evidence gate
- release quality gate
- regression check
- release blockers

Preview 能力：

- RAG export
- 本地 retrieve / ask
- workspace registry / store
- governance workflow
- batch governance
- package lineage
- curated package
- update impact
- platform distribution 与 mock publishing package
- Provider registry、配置校验、redaction、fallback、cost guard
- Provider live smoke，默认关闭，必须显式 opt-in
- Minimal end-to-end portfolio demo workflow
- Parser backend 抽象、parse quality gate、manual review queue 和 trusted KB gate
- Knowledge Runtime Loop：`kb-index`、`kb-query`、`kb-answer`、本地引用答案、低置信拒答、query trace、retrieval quality report 和 RAG eval baseline

Experimental 能力：

- master Skill learning
- derived Skill generator
- mock-first LLM quality assist
- provider readiness
- provider security governance
- opt-in LLM live smoke
- prompt profile versioning
- golden samples
- compatibility matrix
- desktop / web UI

完整矩阵见 [Capability Status](docs/CAPABILITY_STATUS.zh-CN.md)。

## v2.6 Provider Governance

v2.6 新增 Preview 级 Provider 治理能力，覆盖 OpenAI、Anthropic、Gemini、OpenRouter、通用 OpenAI-compatible provider，以及 Qwen DashScope、DeepSeek、Kimi Moonshot、Zhipu GLM、Baidu Qianfan、Tencent Hunyuan、MiniMax、Volcengine Doubao 等国内 Provider。

```powershell
python -m heitang_kb_forge.cli provider-list
python -m heitang_kb_forge.cli provider-config-validate --output .\tmp_v26\validate
python -m heitang_kb_forge.cli provider-health --output .\tmp_v26\health
python -m heitang_kb_forge.cli provider-live-smoke --output .\tmp_v26\live
python -m heitang_kb_forge.cli provider-fallback-test --output .\tmp_v26\fallback --scenario timeout
python -m heitang_kb_forge.cli audit-redaction-check --output .\tmp_v26\redaction
python -m heitang_kb_forge.cli llm-cost-guard --output .\tmp_v26\cost --prompt-chars 13000 --output-tokens 5000
```

默认行为仍然是 mock/offline。真实 provider 调用必须显式开启 live flags，并由本地环境变量提供配置。详见 [v2.6 Provider Governance](docs/V26_PROVIDER_GOVERNANCE.zh-CN.md)。

## v2.7 Demo E2E

v2.7 新增本地离线作品集 demo 工作流。它会构建知识包，运行 quality gate、provider security audit、mock LLM quality gate assist、generic / Codex / OpenClaw 平台导出、release readiness、portfolio report 和 evidence pack。

```powershell
python -m heitang_kb_forge.cli demo-e2e --output .\tmp_demo_e2e
```

该 demo 不运行真实平台 runtime，不启动 MCP server，不自动发布小红书笔记，默认不调用 live provider。

## v2.8 Parser Backend Reliability

v2.8 新增可选 parser backend 与知识可靠性输出。默认 `build`、`batch`、`run`、`pipeline` 行为不变，只有显式启用 parser backend 时才生成新增输出。

```powershell
python -m heitang_kb_forge.cli parser-backend-list
python -m heitang_kb_forge.cli parse-with-backend --backend builtin --input .\examples\quickstart\input --output .\tmp_parse
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_build --parser-backend builtin
```

内置 backend 完全本地运行。Docling 和 Marker 是可选 stub，只有安装 extra 并显式接入本地集成后才会作为外部 parser 使用。v2.8 会写出 parser backend output、parse quality、OCR risk、manual review queue、trust gate 和 knowledge reliability report，不调用网络，也不强制安装外部 parser 依赖。

## v2.9 Knowledge Runtime Loop

v2.9 新增可选本地知识运行闭环。它基于已有知识包构建本地 KB index，执行确定性 query ranking，写出 citation trace，生成带引用的本地答案，在低置信时拒答，并生成 retrieval quality 与 RAG eval baseline 文件。

```powershell
python -m heitang_kb_forge.cli kb-index --package .\tmp_quickstart_output --output .\tmp_kb_runtime
python -m heitang_kb_forge.cli kb-query --package .\tmp_quickstart_output --query "pricing evidence" --output .\tmp_kb_runtime
python -m heitang_kb_forge.cli kb-answer --package .\tmp_quickstart_output --query "pricing evidence" --output .\tmp_kb_runtime
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_build --knowledge-runtime --kb-query "summarize evidence"
```

v2.9 会写出 `kb_index.jsonl`、`kb_index_manifest.json`、`kb_query_result.json`、`kb_query_trace.json`、`kb_citation_trace.json`、`kb_answer.md`、`kb_answer_report.json`、`retrieval_quality_report.json`、`rag_eval_baseline.jsonl` 和 `rag_eval_baseline_report.md`。它不调用 LLM API，不调用 embedding API，不写入向量库，也不真实运行外部 Agent runtime。

## 安装

```powershell
python -m pip install -e ".[dev]"
```

可选组件：

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,web]"
```

## 五分钟 Quickstart

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart_output
python -m heitang_kb_forge.cli quality-gate --workspace .\tmp_quickstart_output --output .\tmp_quality_gate
python -m heitang_kb_forge.cli release-readiness --workspace . --output .\tmp_release_readiness
```

核心输出：

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `quality_report.json`
- `ingest_report.md`

## 核心 CLI

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\output
python -m heitang_kb_forge.cli batch --input .\input --output .\output --domain education --mode teaching
python -m heitang_kb_forge.cli pipeline --config .\examples\configs\kb_forge.v25.yaml
python -m heitang_kb_forge.cli quality-gate --workspace .\output --output .\quality_gate
python -m heitang_kb_forge.cli regression-check --workspace . --output .\regression
```

## v2.9 定位

v2.9 是本地 Knowledge Runtime Loop checkpoint。Runtime 输出默认关闭，离线默认输出不变；本轮验证本地 index / query / answer、引用、拒答、query trace、retrieval quality 和 RAG eval baseline。

## 当前边界

默认不做：

- 调用真实 LLM API
- 调用 embedding API
- 写入向量数据库
- 上传小红书 / XHS
- 真实运行 OpenClaw、Codex、Claude Code 或 MCP runtime
- 启动真实 MCP Server
- 保存真实用户 API key
- SaaS 多租户或权限系统

当前与后续边界：

- v2.6：真实 LLM live smoke 与 provider security governance
- v2.7：minimal end-to-end demo / portfolio release
- v2.8：parser backend 与 knowledge reliability
- v2.9：Knowledge Runtime Loop
- 后续客户端平台集成：飞书 / 个人知识库 / 移动端 / 安装端 / iOS
- v3.x：SaaS / 权限 / 团队协作

## 文档导航

- [Capability Status](docs/CAPABILITY_STATUS.zh-CN.md)
- [Version Matrix](docs/VERSION_MATRIX.zh-CN.md)
- [Release Checklist](docs/RELEASE_CHECKLIST.zh-CN.md)
- [CLI 架构](docs/CLI_ARCHITECTURE.zh-CN.md)
- [Roadmap](docs/ROADMAP.zh-CN.md)
- [Implementation Checkpoints](docs/IMPLEMENTATION_CHECKPOINTS.zh-CN.md)
- [Version Traceability](docs/VERSION_TRACEABILITY.zh-CN.md)
- [Release Readiness](docs/RELEASE_READINESS.zh-CN.md)
- [v2.8 Parser Backend Reliability](docs/V28_PARSER_BACKEND_RELIABILITY.zh-CN.md)
- [v2.9 Knowledge Runtime Loop](docs/V29_KNOWLEDGE_RUNTIME_LOOP.zh-CN.md)
- [Platform Distribution](docs/PLATFORM_DISTRIBUTION.zh-CN.md)
- [Knowledge Ops Guide](docs/KNOWLEDGE_OPS_GUIDE.md)
- [桌面应用指南](docs/DESKTOP_APP_GUIDE.md)

## License

MIT License. See [LICENSE](LICENSE) for details.

## 作品集 / Demo

面试和作品集展示文档：

- [项目一页纸](docs/PROJECT_ONE_PAGER.zh-CN.md)
- [面试讲法](docs/INTERVIEW_TALK_TRACK.zh-CN.md)
- [演示脚本](docs/DEMO_SCRIPT.zh-CN.md)
- [作品集介绍](docs/PORTFOLIO_PRESENTATION.zh-CN.md)
- [项目架构概览](docs/PROJECT_ARCHITECTURE_OVERVIEW.zh-CN.md)

运行本地端到端 Demo：

```powershell
python -m heitang_kb_forge.cli demo-e2e --output ./tmp_demo_e2e
```

## Knowledge Workbench 终极目标

HeiTang KB Forge Core 现在定义为 HeiTang Knowledge Workbench 里的知识供应链核心 Skill。

战略文档：

- [终极目标](docs/WORKBENCH_FINAL_TARGET.zh-CN.md)
- [多知识库 / 多 Agent / 记忆隔离架构](docs/MULTI_KB_MULTI_AGENT_MEMORY_ARCHITECTURE.zh-CN.md)
- [版本计划](docs/WORKBENCH_VERSION_PLAN.zh-CN.md)
- [外部项目接入清单](docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md)

