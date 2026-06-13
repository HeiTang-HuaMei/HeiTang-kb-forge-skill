# HeiTang Knowledge Workbench

An offline-first Agent Knowledge Supply Chain Workbench for turning local source materials into standardized, traceable, searchable, auditable, and reusable knowledge assets.

Current Core: v4.2.0

Status: v4.2.0 P2.2 Knowledge-to-Methodology-to-Skill-Suite Industrial Baseline after v4.1.1 P2.2 Entry Gate / Test Governance Stable Baseline.

For quick understanding:
- Product positioning: [docs/CURRENT_TRUTH.md](docs/CURRENT_TRUTH.md)
- Capability matrix: [docs/CAPABILITY_MATRIX.md](docs/CAPABILITY_MATRIX.md)
- AIGC book content pipeline scenario: [docs/AIGC_BOOK_CONTENT_PIPELINE.md](docs/AIGC_BOOK_CONTENT_PIPELINE.md)
- P2.1 parser/OCR backend evidence: [docs/audits/p2_1_parser_ocr_backends/](docs/audits/p2_1_parser_ocr_backends/)
- Validation strategy: [docs/testing/VALIDATION_STRATEGY.md](docs/testing/VALIDATION_STRATEGY.md)
- Validation gate manifest: [docs/testing/VALIDATION_GATE_MANIFEST.json](docs/testing/VALIDATION_GATE_MANIFEST.json)
- Test pruning register: [docs/testing/TEST_PRUNING_REGISTER.md](docs/testing/TEST_PRUNING_REGISTER.md)
- External benchmarks and post-v4 roadmap: [docs/roadmap/external_projects/](docs/roadmap/external_projects/)
- S/A external project contract inclusion: [docs/roadmap/external_projects/S_A_CONTRACT_INCLUSION.md](docs/roadmap/external_projects/S_A_CONTRACT_INCLUSION.md)
- Chinese README: [README.zh-CN.md](README.zh-CN.md)

## What this project is

HeiTang Knowledge Workbench is the Core engine for a local-first Agent knowledge workflow. It ingests local files, turns them into evidence-carrying knowledge packages, and exposes the assets needed by RAG, verification, document generation, structured Skill packages, and local Agent workflows.

The repository name still contains `Skill` because the project started from a Skill-first package surface. The current Core is broader: it is a headless knowledge supply chain that can produce Skill packages, Agent packages, reports, artifacts, indexes, and Workbench contracts. The UI remains a presentation layer, not the Core product engine.

## Current status

Current Core package version: `4.2.0`
Current stable release: `v4.2.0`
Previous stable release: `v4.1.1`
Historical stable release: `v4.0.0`

- v4.2.0 completes the P2.2 Knowledge-to-Methodology-to-Skill-Suite industrial baseline.
- Existing knowledge asset packages can be transformed into evidence windows, methodology maps, skill candidates, Skill Suite hierarchy, Skill Pack exports, validation/diff/installability reports, and suite governance evidence.
- v4.1.1 remains the P2.2 Entry Gate / Test Governance Stable Baseline.
- P2.1 Parser/OCR pluggable backend runtime remains release-hardened from v4.1.0.
- Docling, PaddleOCR, and Unstructured are real opt-in local runtime adapters, dependency-gated and not bundled.
- Latest P2.1 proof: `docs/audits/p2_1_parser_ocr_backends/`
- Latest live runtime proof: `docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Unstructured stable surface in this release is `.md/.txt`; PDF/DOCX/image extras remain future hardening.
- Builtin parser remains the default fallback path.
- v4.1.0 remains the historical Parser/OCR stable tag, v4.1.1 remains the historical P2.2 Entry Gate tag, and v4.0.0 remains an untouched historical stable tag.
- Final architecture truth: [docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md](docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md)
- `ready_for_v4_rc=true` remains historical P1 evidence; P2.3 has not started.

## Core capabilities

- Local ingestion for Markdown, TXT, DOCX, text PDF, image/OCR routes, CSV/TSV/XLSX, HTML, EPUB, ZIP, and mixed source sets.
- Standard knowledge package outputs: `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, and `ingest_report.md`.
- Deterministic query rewrite, retrieval planning, local indexing, local JSON vector query, hybrid retrieval, rerank, evidence selection, and knowledge accuracy reports.
- RAG validation paths for answering retrieval and verification retrieval, including claim, contradiction, freshness, and no-answer evidence handling.
- Grounded Markdown, DOCX, PDF, and PPTX document generation.
- Skill-first package generation for Codex, Claude Code, OpenClaw, and generic local Agent integrations.
- P2.2 Skill Suite flow: methodology extraction, evidence-backed candidate planning, Planning/Functional/Atomic hierarchy generation, routing rules, dependency graph, validation, diff, installability, governance report, and controlled Skill Pack export.
- Standalone and KB-bound Agent package surfaces, local runtime smoke, KB boundary checks, memory policy reports, and mother/child orchestration contracts.
- Local workspace registry, storage reports, lifecycle plans, artifact registries, and P1 Workbench contract pack.
- Parser/OCR backend runtime registry, matrix, inspect, smoke, live acceptance replay, and release evidence reports for opt-in Docling, PaddleOCR, and Unstructured adapters.
- Privacy and security reports for no hidden upload, secret redaction, optional provider boundaries, and local-first operation.

## Quick start

Install the local development package:

```powershell
python -m pip install -e ".[dev]"
```

Optional local parser extras:

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,parser-paddleocr,parser-unstructured,web]"
```

Build and inspect a local knowledge package:

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
- The P1 local Workbench gate, rc.1 acceptance, and release hardening evidence remain attached as v4.0.0 historical release proof.
- Historical P1 evidence may still contain `not_v4_0_workbench_rc=true` as a time-point boundary from before the stable release.
- OpenDataLoader and MinerU remain external backend candidates / planned adapters only.
- Docling, PaddleOCR, and Unstructured are implemented as opt-in local parser/OCR runtime adapters; they are dependency-gated, not bundled, not default Core parsing, and not static Workbench-executable external projects.
- P2.1 validates Docling on Markdown/TXT live acceptance samples, PaddleOCR on a PNG OCR sample, and Unstructured on `.md/.txt`; broader surfaces remain explicitly bounded by [backend capability boundaries](docs/audits/p2_1_parser_ocr_backends/backend_capability_boundaries.md).
- S/A external projects are included as contract, matrix, provider boundary, and UI visibility entries only; this does not implement their functionality.
- External provider, secret, and network-dependent actions require explicit user configuration and are not counted as real-local passed.
- External GitHub benchmark implementation is post-v4 and is not part of this gate.
- Core tests do not require real LLM/API/network calls.
- Core does not save real user API keys, raw private input, local provider profiles, or local config outputs.
- Core does not claim SaaS multi-tenancy, team permissions, cloud sync, or platform-hosted user data.

The canonical docs entry is [docs/DOCS_INDEX.md](docs/DOCS_INDEX.md). Suggested GitHub About copy lives in [docs/GITHUB_PROFILE_COPY.md](docs/GITHUB_PROFILE_COPY.md).

## License

MIT License. See [LICENSE](LICENSE).
