# HeiTang KB Forge Skill

[中文说明](README.zh-CN.md) | English

Current Core version: `3.12.0-alpha.1`

HeiTang KB Forge is an offline-first, local-first Core Skill for building Agent-ready knowledge packages. It turns local source material into standardized, traceable, searchable, auditable, and reusable knowledge assets for RAG, document generation, Skill packages, and local Agent workflows.

## Current Status

Core pre-v4 RC readiness is complete for the latest Core P0 proof:

- Latest Core P0 proof: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- Remaining Core P0: none in the latest pre-v4 P0 proof.
- Baseline evidence before this documentation governance pass: Core main `053a6a6`, GitHub CI run `27140288050` success.

v4.0 is not released, not tagged, and not started. v4.0 has not been released. UI full-operation remains blocked, so this repository must not claim a full user-operable Workbench.

Current truth lives in [Current Truth](docs/00_overview/CURRENT_TRUTH.md) and [Final Product Architecture Truth](docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md).

## Core Capabilities

- Multi-format local ingestion for Markdown, TXT, DOCX, text PDF, images/OCR routes, CSV/TSV/XLSX, HTML, EPUB, ZIP, and mixed source sets.
- Standard package outputs: `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, and `ingest_report.md`.
- Deterministic query rewrite, retrieval planning, local indexing, local JSON vector query, hybrid retrieval, rerank, evidence selection, and knowledge accuracy reports.
- Grounded Markdown, DOCX, PDF, and PPTX document generation.
- Skill-first Agent package surface for Codex, Claude Code, OpenClaw, and generic local Agent integrations.
- Local mother/child Agent runtime smoke, KB boundary checks, memory policy reports, workspace storage, lifecycle reports, and release hardening gates.
- Local privacy and security reports for no hidden upload, secret redaction, no platform-hosted user data, and optional provider boundaries.

See the full [Capability Matrix](docs/00_overview/CAPABILITY_MATRIX.md). Parser backend positioning lives in [Parser Backend Strategy](docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.md).

## Quick Start

Install the local development package:

```powershell
python -m pip install -e ".[dev]"
```

Optional local parser extras:

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,web]"
```

Build and inspect a local knowledge package:

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart_output
python -m heitang_kb_forge.cli check-contract --package .\tmp_quickstart_output --output .\tmp_contract
python -m heitang_kb_forge.cli kb-index --package .\tmp_quickstart_output --output .\tmp_kb_index
python -m heitang_kb_forge.cli kb-query --package .\tmp_quickstart_output --query "Summarize the package" --output .\tmp_kb_query
python -m heitang_kb_forge.cli generate-documents --package .\tmp_quickstart_output --output .\tmp_documents
```

Run the strict final pre-v4 Core audit when evidence inputs are available:

```powershell
python -m heitang_kb_forge.cli final-pre-v4-audit --core-repo . --output .\tmp_final_audit
```

## Documentation

The canonical documentation entry is [Docs Index](docs/DOCS_INDEX.md). Start there for:

- current truth and release state
- capability matrix
- P1 UI Core Parity and P2 Productization roadmaps
- command reference, user manual, troubleshooting, architecture, and privacy docs
- root report/audit/gate evidence policy

Useful entry points:

- [Current Truth](docs/00_overview/CURRENT_TRUTH.md)
- [Capability Matrix](docs/00_overview/CAPABILITY_MATRIX.md)
- [Parser Backend Strategy](docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.md)
- [P1 UI Core Parity](docs/10_roadmap/P1_UI_CORE_PARITY.md)
- [P2 Productization](docs/10_roadmap/P2_PRODUCTIZATION.md)
- [Documentation Governance](docs/DOCUMENTATION_GOVERNANCE.md)

## Roadmap State

- Core pre-v4 RC readiness: complete for the latest Core P0 gate.
- P1 UI Core Parity: not complete; UI full-operation remains blocked.
- P2 Productization: future work after P1 UI Core Parity evidence exists.
- v4.0: not started, not released, not tagged.

UI information architecture is frozen as a planning contract, but the UI is a presentation layer. It is not the Core product engine, and this README does not claim complete Workbench operation.

## Root Evidence Surface

Only the current root gate JSON files are kept at the repository root. Historical process documents and old root reports belong in git history, tags, or scoped audit proof directories. Use [Documentation Governance](docs/DOCUMENTATION_GOVERNANCE.md) and [Docs Index](docs/DOCS_INDEX.md) first.

## Boundaries

HeiTang KB Forge does not by default:

- call real LLM APIs
- call embedding APIs
- upload user documents or generated packages
- save real user API keys
- run external Agent runtimes
- start a real MCP server
- provide SaaS multi-tenancy, team permissions, cloud sync, or platform-hosted user data
- claim complete Workbench operation or v4.0 release readiness before the separate UI full-operation gate passes

LLM remains optional only; Core tests do not require real LLM/API/network calls.

## License

MIT License. See [LICENSE](LICENSE).
