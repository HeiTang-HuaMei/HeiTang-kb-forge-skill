# HeiTang KB Forge Skill

[English](README.md) | 中文说明

当前 UI package 版本：`4.1.1`

当前 release line：`v4.1.1` Test Framework Governance

发布状态：在 v4.1.0 Parser/OCR Workbench 同步之后进入 v4.1.1 UI test framework governance line。`v4.0.0` 与 `v4.1.0` tag 保持不变；v4.1.1 在 Chunked Full Gate、tag、release 与 release-check evidence 完成前不是 stable。

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

## 安装

```powershell
python -m pip install -e ".[dev]"
```

可选组件：

```powershell
python -m pip install -e ".[ocr,pdf-table,web]"
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

## v2.5.1 定位

v2.5.1 是 release engineering 和 CLI architecture convergence checkpoint。它统一版本、收敛 README、拆分能力状态、增强 CI 与 release-readiness，并开始 CLI 命令模块化收敛。

v2.5.0-dev 仍然是 release quality gate 功能 checkpoint。

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

后续边界：

- v2.6：真实 LLM live smoke 与 provider security governance
- v2.7：minimal end-to-end demo / portfolio release
- v2.8：domain Skill factory
- v2.9：飞书 / 个人知识库 / 移动端 / 安装端 / iOS
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

P2.1 / v4.1.0 中，Workbench 额外消费 Core runtime baseline commit `576a62075dc1ecbe00388bb0569fd1fc767be7cb` 生成的 parser backend matrix。界面通过 dashboard summary cards、边界 callout、matrix table、backend detail panels 与 audit evidence rows 展示 builtin fallback、Docling、PaddleOCR、Unstructured 的安装模式、最近验收状态、证据路径与已知限制。Docling 与 PaddleOCR 是 optional dependency gated 的真实 runtime 集成；Unstructured 本轮稳定表面只声明 `.md/.txt`。UI 不提供 parser/OCR runtime 执行控件，也不声明默认安装重型依赖。

v4.1.1 中，UI package 增加 test framework governance：validation gate manifest、changed-file impact selector、dry-run / executable gate runner、pytest markers 和 obsolete-test pruning register。parser/OCR fixture 仍是 v4.1.0 历史 Core evidence，不改写成新的 runtime execution 声明。

当前 UI package 保留历史 v4.0.0 边界证据与 v4.1.0 parser/OCR evidence 可见性；历史 Core stable commit 仍为 `0217e54b162871e7c40c31ff3d0cc72e8ba78f06`。

战略文档：

- [终极目标](docs/WORKBENCH_FINAL_TARGET.zh-CN.md)
- [多知识库 / 多 Agent / 记忆隔离架构](docs/MULTI_KB_MULTI_AGENT_MEMORY_ARCHITECTURE.zh-CN.md)
- [版本计划](docs/WORKBENCH_VERSION_PLAN.zh-CN.md)
- [外部项目接入清单](docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md)

