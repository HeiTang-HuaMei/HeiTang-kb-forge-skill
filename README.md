# HeiTang KB Forge Skill

An offline-first Agent Knowledge Supply Chain Core for turning local source materials into standardized, traceable, searchable, auditable, and reusable knowledge assets.

Current Core: v4.0.0

Status: v4.0.0 stable release after P1 Final Gate, External Project Registry, S/A Contract Inclusion, rc.1 acceptance, and release hardening.

For quick understanding:
- Product positioning: [docs/CURRENT_TRUTH.md](docs/CURRENT_TRUTH.md)
- Capability matrix: [docs/CAPABILITY_MATRIX.md](docs/CAPABILITY_MATRIX.md)
- AIGC book content pipeline scenario: [docs/AIGC_BOOK_CONTENT_PIPELINE.md](docs/AIGC_BOOK_CONTENT_PIPELINE.md)
- External benchmarks and post-v4 roadmap: [docs/roadmap/external_projects/](docs/roadmap/external_projects/)
- S/A external project contract inclusion: [docs/roadmap/external_projects/S_A_CONTRACT_INCLUSION.md](docs/roadmap/external_projects/S_A_CONTRACT_INCLUSION.md)
- Chinese README: [README.zh-CN.md](README.zh-CN.md)

## What this project is

HeiTang KB Forge Skill is the Core engine for a local-first Agent knowledge workflow. It ingests local files, turns them into evidence-carrying knowledge packages, and exposes the assets needed by RAG, verification, document generation, structured Skill packages, and local Agent workflows.

The repository name still contains `Skill` because the project started from a Skill-first package surface. The current Core is broader: it is a headless knowledge supply chain that can produce Skill packages, Agent packages, reports, artifacts, indexes, and Workbench contracts. The UI remains a presentation layer, not the Core product engine.

## Current status

Current Core package version: `4.0.0`
Current stable release: `v4.0.0`

- Core pre-v4 RC readiness is complete for the latest Core P0 proof.
- P1 local Workbench final gate re-run is complete for v4 RC readiness.
- Pre-v4 External Project Registry and S/A Contract Inclusion are complete.
- Latest P1 proof: `docs/audits/p1_final_gate_rerun/`
- Latest Core P0 proof: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- Remaining Core P0: none in the latest pre-v4 P0 proof.
- Final architecture truth: [docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md](docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md)
- `ready_for_v4_rc=true`; rc.1 acceptance and hardening evidence have been promoted into the stable `v4.0.0` release line.

## Core capabilities

- Local ingestion for Markdown, TXT, DOCX, text PDF, image/OCR routes, CSV/TSV/XLSX, HTML, EPUB, ZIP, and mixed source sets.
- Standard knowledge package outputs: `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, and `ingest_report.md`.
- Deterministic query rewrite, retrieval planning, local indexing, local JSON vector query, hybrid retrieval, rerank, evidence selection, and knowledge accuracy reports.
- RAG validation paths for answering retrieval and verification retrieval, including claim, contradiction, freshness, and no-answer evidence handling.
- Grounded Markdown, DOCX, PDF, and PPTX document generation.
- Skill-first package generation for Codex, Claude Code, OpenClaw, and generic local Agent integrations.
- Standalone and KB-bound Agent package surfaces, local runtime smoke, KB boundary checks, memory policy reports, and mother/child orchestration contracts.
- Local workspace registry, storage reports, lifecycle plans, artifact registries, and P1 Workbench contract pack.
- Privacy and security reports for no hidden upload, secret redaction, optional provider boundaries, and local-first operation.

## Quick start

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

## Scenario entry points

**Agent Knowledge Base**

Build local source material into an Agent-ready knowledge package with traceable chunks, cards, glossary, QA pairs, and quality reports. Start with `build`, then validate with `check-contract`, and bind through Skill or Agent package generation.

**RAG / Verification**

Use deterministic query planning, local retrieval, hybrid ranking, evidence selection, claim verification, contradiction detection, and freshness checks. The Core separates answering retrieval from validation retrieval so reports can show why an answer is grounded or blocked.

**Structured Skill Factory**

Generate structured Skill packages from books or knowledge packages, including `SKILL.md`, manifests, prompts, test prompts, token-budget reports, installability checks, and runtime profile guidance for Codex, Claude Code, OpenClaw, and local integrations.

**AIGC Book Content Pipeline**

Use the Core to turn source libraries, editorial notes, manuscripts, policy files, and reference material into reusable AIGC production assets: package inventory, RAG verification, structured Skill outputs, Agent packages, evidence appendices, and generated Markdown/DOCX/PDF/PPTX documents. See [docs/AIGC_BOOK_CONTENT_PIPELINE.md](docs/AIGC_BOOK_CONTENT_PIPELINE.md).

**Local Workbench**

Core emits Workbench contracts, registries, schemas, deterministic fixtures, dry-run actions, smoke checks, reports, and artifact metadata for a local desktop Workbench. The P1-RWF-V2 evidence and UI consumption pass have been re-run into `ready_for_v4_rc=true`.
UI information architecture is frozen as a planning contract, and the UI remains a presentation layer.

## Repository status / honesty boundary

- This is the Core repository only; visual UI work belongs outside this Core pass.
- The P1 local Workbench gate, rc.1 acceptance, and release hardening evidence are complete for stable `v4.0.0`.
- Historical P1 evidence may still contain `not_v4_0_workbench_rc=true` as a time-point boundary from before the stable release.
- OpenDataLoader, PaddleOCR, and MinerU are external backend candidates / planned adapters only; they are not completed Core integrations.
- S/A external projects are included as contract, matrix, provider boundary, and UI visibility entries only; this does not implement their functionality.
- External provider, secret, and network-dependent actions require explicit user configuration and are not counted as real-local passed.
- External GitHub benchmark implementation is post-v4 and is not part of this gate.
- Core tests do not require real LLM/API/network calls.
- Core does not save real user API keys, raw private input, local provider profiles, or local config outputs.
- Core does not claim SaaS multi-tenancy, team permissions, cloud sync, or platform-hosted user data.

The canonical docs entry is [docs/DOCS_INDEX.md](docs/DOCS_INDEX.md). Suggested GitHub About copy lives in [docs/GITHUB_PROFILE_COPY.md](docs/GITHUB_PROFILE_COPY.md).

## License

MIT License. See [LICENSE](LICENSE).
