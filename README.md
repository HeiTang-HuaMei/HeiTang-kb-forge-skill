# HeiTang KB Forge Skill

[中文说明](README.zh-CN.md) | English

Current UI package version: `4.1.1`

Current stable release: `v4.1.1` Test Framework Governance

Release status: v4.1.1 UI test framework governance stable release after v4.1.0 Parser/OCR Workbench sync. The `v4.0.0` and `v4.1.0` tags remain untouched; the v4.1.0 parser/OCR fixture remains historical Core evidence consumed by the static Workbench.

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

## Install

```powershell
python -m pip install -e ".[dev]"
```

Optional extras:

```powershell
python -m pip install -e ".[ocr,pdf-table,web]"
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

## v2.5.1 Focus

v2.5.1 is a release engineering and CLI architecture convergence checkpoint. It aligns versions, trims README scope, separates capability status, strengthens CI and release-readiness checks, and starts CLI command-module convergence.

v2.5.0-dev remains the release quality gate feature checkpoint.

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

Future boundaries:

- v2.6: real LLM live smoke and provider security governance
- v2.7: minimal end-to-end demo / portfolio release
- v2.8: domain Skill factory
- v2.9: Feishu / personal KB / mobile / installer / iOS
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

Run the local end-to-end demo:

```powershell
python -m heitang_kb_forge.cli demo-e2e --output ./tmp_demo_e2e
```

## Knowledge Workbench Target

HeiTang KB Forge Core is now defined as the knowledge supply-chain core Skill inside the larger HeiTang Knowledge Workbench direction.

## Workbench UI Boundary

The optional Workbench UI defaults to a black / white / gray premium Windows desktop workbench style. It supports light / dark mode and a zh-CN / en-US language switch.

The current UI is a P1 final gate re-run evidence UI consumption pass verified against Core commit `f5fa13bb11211abb0bcecaccd845e545a2dacad3` and Core CI run `27210849617`. It consumes a deterministic copied Core `workbench-contracts --profile p1` fixture for 16 P1 Core pages, 110 actions, 109 reports, 101 artifacts, 20 error codes, 6 templates, task schema, capability matrix, and gate status. It also displays copied P1-RWF-V2 and P1 final-gate evidence with `drift_count=0`, 57 local execution targets passed, 10 user paths passed, `p1_full_operation_gate_status: ready_for_v4_rc`, and `ready_for_v4_rc=true`.

It also surfaces S/A external capability contract-inclusion fixtures from Core commit `c30f8adcadfedb30cb974eb62cc02a38c35a5158` and CI run `27221946149`. These entries are visibility and boundary data only: planned/future/provider-required projects are not installed, not local-ready, and not executable from the UI.

For P2.1 / v4.1.0, the Workbench also consumes the Core parser backend matrix from runtime baseline commit `576a62075dc1ecbe00388bb0569fd1fc767be7cb`. It shows builtin fallback, Docling, PaddleOCR, and Unstructured install mode, last acceptance status, evidence path, and known limitations through dashboard summary cards, callouts, a matrix table, backend detail panels, and audit evidence rows. Docling and PaddleOCR are optional dependency gated real-runtime integrations; Unstructured is optional dependency gated with stable `.md/.txt` surface only. The UI does not expose parser/OCR runtime execution controls and does not claim default heavy dependency bundling.

The latest stable UI line is v4.1.0 Parser/OCR evidence sync. The current v4.1.1 line adds test governance and must not be called stable until its gates, tag, release, and release-check evidence are complete.

For v4.1.1, the UI package adds test framework governance: a validation gate manifest, changed-file impact selector, dry-run/executable gate runner, pytest markers, and an obsolete-test pruning register. The parser/OCR fixture remains v4.1.0 historical Core evidence; it is not rewritten as a new runtime execution claim.

The historical v4.0.0 boundary evidence still references Core stable commit `0217e54b162871e7c40c31ff3d0cc72e8ba78f06`.

This UI package keeps the historical v4.0.0 boundary evidence and v4.1.0 parser/OCR evidence visibility. The copied historical P1 evidence keeps `not_v4_0_workbench_rc=true`; unsupported provider, secret, network, planned-adapter, and parser/OCR runtime operations render disabled or evidence-only with `blocked_reason` or explicit optional dependency boundaries.

Strategic docs:

- [Final Target](docs/WORKBENCH_FINAL_TARGET.md)
- [Multi-KB / Multi-Agent Memory Architecture](docs/MULTI_KB_MULTI_AGENT_MEMORY_ARCHITECTURE.md)
- [Workbench Version Plan](docs/WORKBENCH_VERSION_PLAN.md)
- [External Project Adoption](docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md)

