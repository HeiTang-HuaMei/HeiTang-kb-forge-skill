# HeiTang KB Forge Skill

[中文说明](README.zh-CN.md) | English

Current version: `2.5.1-alpha.1`

Release status: alpha release-engineering checkpoint. This is not a stable release.

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

Experimental capabilities:

- Master Skill learning
- Derived Skill generator
- Mock-first LLM quality assist
- Provider readiness
- Prompt profile versioning
- Golden samples
- Compatibility matrix
- Desktop / web UI

See [Capability Status](docs/CAPABILITY_STATUS.md) for the full Stable / Preview / Experimental / Roadmap / Reserved / Deprecated / Out of Scope matrix.

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
- v2.7: runtime compatibility smoke
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
