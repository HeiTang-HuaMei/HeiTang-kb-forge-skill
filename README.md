# HeiTang KB Forge Skill

[中文说明](README.zh-CN.md) | English

Current version: `2.9.0-alpha.1`

Release status: alpha Knowledge Runtime Loop checkpoint. This is not a stable release.

HeiTang KB Forge is an offline-first, agent-callable knowledge supply-chain Skill. It turns multi-format source material into standardized, auditable, reviewable, and retrievable knowledge asset packages for Agent and RAG workflows.

The project focuses on content reliability, accuracy, evidence boundaries, reviewability, and clear mock/live separation.

## Capability Status

Stable local capabilities:

- Markdown / TXT / DOCX / text-based PDF build
- Standard 7-file knowledge package output
- Manifest, chunks, cards, QA, glossary, ingest report, quality report
- Contract v2 checks
- Basic batch build
- Lifecycle check
- Evidence gate
- Release quality gate
- Regression check
- Release blockers

Preview capabilities:

- RAG export
- Local retrieve / ask
- Workspace registry / store
- Governance workflow
- Batch governance
- Package lineage
- Curated package
- Update impact
- Platform distribution and mock publishing packages
- Provider registry, config validation, redaction, fallback, and cost guard
- Provider live smoke, disabled unless explicitly opted in
- Minimal end-to-end portfolio demo workflow
- Parser backend abstraction, parse quality gate, manual review queue, and trusted KB gate
- Knowledge Runtime Loop: `kb-index`, `kb-query`, `kb-answer`, cited local answers, low-confidence refusal, query trace, retrieval quality report, and RAG eval baseline
- Document Generation and Local Workspace Loops: grounded document exports, workspace registries, storage usage, dedup/cleanup plans, memory lifecycle/token budget contracts, local PDF Markdown preprocessing, parser benchmark, PDF token reduction, and no-cloud-upload reports

Experimental capabilities:

- Master Skill learning
- Derived Skill generator
- Mock-first LLM quality assist
- Provider readiness
- Provider security governance
- Opt-in LLM live smoke
- Prompt profile versioning
- Golden samples
- Compatibility matrix
- Desktop / web UI

See [Capability Status](docs/CAPABILITY_STATUS.md) for the full Stable / Preview / Experimental / Roadmap / Reserved / Deprecated / Out of Scope matrix.

## v2.6 Provider Governance

v2.6 adds Preview provider governance for OpenAI, Anthropic, Gemini, OpenRouter, generic OpenAI-compatible providers, and domestic providers including Qwen DashScope, DeepSeek, Kimi Moonshot, Zhipu GLM, Baidu Qianfan, Tencent Hunyuan, MiniMax, and Volcengine Doubao.

```powershell
python -m heitang_kb_forge.cli provider-list
python -m heitang_kb_forge.cli provider-config-validate --output .\tmp_v26\validate
python -m heitang_kb_forge.cli provider-health --output .\tmp_v26\health
python -m heitang_kb_forge.cli provider-live-smoke --output .\tmp_v26\live
python -m heitang_kb_forge.cli provider-fallback-test --output .\tmp_v26\fallback --scenario timeout
python -m heitang_kb_forge.cli audit-redaction-check --output .\tmp_v26\redaction
python -m heitang_kb_forge.cli llm-cost-guard --output .\tmp_v26\cost --prompt-chars 13000 --output-tokens 5000
```

Default behavior remains mock/offline. Real provider calls require explicit live flags and local environment variables. See [v2.6 Provider Governance](docs/V26_PROVIDER_GOVERNANCE.md).

## v2.7 Demo E2E

v2.7 adds a local offline portfolio demo workflow. It builds a knowledge package, runs quality gate, provider security audit, mock LLM quality gate assist, generic/Codex/OpenClaw platform exports, release readiness, a portfolio report, and an evidence pack.

```powershell
python -m heitang_kb_forge.cli demo-e2e --output .\tmp_demo_e2e
```

The demo does not run real platform runtimes, start an MCP server, publish to Xiaohongshu, or call live providers by default.

## v2.8 Parser Backend Reliability

v2.8 adds opt-in parser backend and knowledge reliability outputs. Default `build`, `batch`, `run`, and `pipeline` behavior remains unchanged unless parser backend mode is enabled.

```powershell
python -m heitang_kb_forge.cli parser-backend-list
python -m heitang_kb_forge.cli parse-with-backend --backend builtin --input .\examples\quickstart\input --output .\tmp_parse
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_build --parser-backend builtin
```

The built-in backend is local. Docling and Marker adapters are optional stubs unless their extras are installed and a local integration is explicitly enabled. v2.8 writes parser backend output, parse quality, OCR risk, manual review queue, trust gate, and knowledge reliability reports. It does not call network services or make external parser dependencies mandatory.

## v2.9 Knowledge Runtime Loop

v2.9 adds an opt-in local runtime loop over an existing knowledge package. It builds a local KB index, runs deterministic query ranking, writes citation traces, produces a cited answer, refuses low-confidence answers, and generates retrieval quality plus RAG eval baseline files.

Commands include `kb-index`, `kb-query`, `kb-answer`, and `build --knowledge-runtime`. See [v2.9 Knowledge Runtime Loop](docs/V29_KNOWLEDGE_RUNTIME_LOOP.md).

## v3.0 Document Generation Loop

v3.0 adds an opt-in local document generation loop over an existing knowledge package. It generates grounded Markdown, DOCX, PDF, and PPTX exports, writes generation and validation reports, and blocks strict generation from draft or untrusted parser output.

Commands include `generate-md`, `generate-documents`, and `build --document-generation`. Config-driven runs support `document_generation.enabled`, `formats`, `template`, and `grounding_policy`. See [v3.0 Document Generation Loop](docs/V30_DOCUMENT_GENERATION.md).

## Install

```powershell
python -m pip install -e ".[dev]"
```

Optional extras:

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,web]"
```

## Five-Minute Quickstart

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart_output
python -m heitang_kb_forge.cli quality-gate --workspace .\tmp_quickstart_output --output .\tmp_quality_gate
python -m heitang_kb_forge.cli release-readiness --workspace . --output .\tmp_release_readiness
```

Expected core output:

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `quality_report.json`
- `ingest_report.md`

## Core CLI

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\output
python -m heitang_kb_forge.cli batch --input .\input --output .\output --domain education --mode teaching
python -m heitang_kb_forge.cli pipeline --config .\examples\configs\kb_forge.v25.yaml
python -m heitang_kb_forge.cli quality-gate --workspace .\output --output .\quality_gate
python -m heitang_kb_forge.cli regression-check --workspace . --output .\regression
```

## Boundaries

By default, HeiTang KB Forge does not:

- call real LLM APIs
- call embedding APIs
- write to vector databases
- upload to Xiaohongshu / XHS
- run OpenClaw, Codex, Claude Code, or MCP runtimes
- start a real MCP Server
- save real user API keys
- provide SaaS multi-tenancy or permissions

Current and future boundaries:

- v2.6: real LLM live smoke and provider security governance
- v2.7: minimal end-to-end demo / portfolio release
- v2.8: parser backend and knowledge reliability
- v2.9: Knowledge Runtime Loop
- v3.0: Document Generation Loop
- future client platform integrations: Feishu / personal KB / mobile / installer / iOS
- v3.x: SaaS / permissions / team collaboration

## Documentation

- [Capability Status](docs/CAPABILITY_STATUS.md)
- [Version Matrix](docs/VERSION_MATRIX.md)
- [Release Checklist](docs/RELEASE_CHECKLIST.md)
- [CLI Architecture](docs/CLI_ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Implementation Checkpoints](docs/IMPLEMENTATION_CHECKPOINTS.md)
- [Version Traceability](docs/VERSION_TRACEABILITY.md)
- [Release Readiness](docs/RELEASE_READINESS.md)
- [v2.8 Parser Backend Reliability](docs/V28_PARSER_BACKEND_RELIABILITY.md)
- [v2.9 Knowledge Runtime Loop](docs/V29_KNOWLEDGE_RUNTIME_LOOP.md)
- [v3.0 Document Generation Loop](docs/V30_DOCUMENT_GENERATION.md)
- [v3.1 Agent / Skill Factory](docs/V31_KNOWLEDGE_BOUND_FACTORY.md)
- [v3.2 Multi-KB Orchestration](docs/V32_MULTI_KB_ORCHESTRATION.md)
- [v3.3 Skill Reverse and Fusion](docs/V33_SKILL_REVERSE_FUSION.md)
- [v3.4 Workbench Contracts](docs/V34_WORKBENCH_CONTRACTS.md)
- [Platform Distribution](docs/PLATFORM_DISTRIBUTION.md)
- [Knowledge Ops Guide](docs/KNOWLEDGE_OPS_GUIDE.md)
- [Desktop App Guide](docs/DESKTOP_APP_GUIDE.md)

## License

MIT License. See [LICENSE](LICENSE) for details.

## Portfolio / Demo

For interview and portfolio presentation, see:

- [Project One-Pager](docs/PROJECT_ONE_PAGER.md)
- [Interview Talk Track](docs/INTERVIEW_TALK_TRACK.md)
- [Demo Script](docs/DEMO_SCRIPT.md)
- [Portfolio Presentation](docs/PORTFOLIO_PRESENTATION.md)
- [Project Architecture Overview](docs/PROJECT_ARCHITECTURE_OVERVIEW.md)

## Knowledge Workbench Target

HeiTang KB Forge Core is now defined as the knowledge supply-chain core Skill inside the larger HeiTang Knowledge Workbench direction.

Strategic docs:

- [Final Target](docs/WORKBENCH_FINAL_TARGET.md)
- [Multi-KB / Multi-Agent Memory Architecture](docs/MULTI_KB_MULTI_AGENT_MEMORY_ARCHITECTURE.md)
- [Workbench Version Plan](docs/WORKBENCH_VERSION_PLAN.md)
- [External Project Adoption](docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md)

