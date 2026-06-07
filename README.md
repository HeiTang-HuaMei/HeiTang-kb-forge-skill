# HeiTang KB Forge Skill

[中文说明](README.zh-CN.md) | English

Current Core version: `3.12.0-alpha.1`

Current project stage: pre-v4.0 industrial acceptance audit / local Workbench RC preparation.

Release status: local-first Knowledge Workbench Core is nearing v4.0 RC, but v4.0 has not been released or tagged. The final pre-v4 gate is still auditing product truth, Core/UI contract drift, security/privacy, scale readiness, user workflows, generated artifacts, and documentation operability.

HeiTang KB Forge is an offline-first, local-first knowledge supply-chain Core Skill. It turns source material into standardized, auditable, retrievable knowledge packages, then supports deterministic local query planning, retrieval quality checks, knowledge accuracy reports, grounded document generation, Skill/Agent package generation, local mother/child Agent runtime smoke, workspace storage and memory lifecycle reports, Golden Demo acceptance, and product hardening gates.

## Implemented Core Surface

- Multi-format local build for Markdown, TXT, DOCX, text PDF, images/OCR routes, CSV/TSV/XLSX, HTML, EPUB, and ZIP through local parser paths and optional extras.
- Standard knowledge package outputs: `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, and `ingest_report.md`.
- v3.0 Document Generation Loop: grounded Markdown, DOCX, PDF, and PPTX export commands and reports.
- v3.7 Query Rewrite & Retrieval Planning: deterministic normalization, rewrite, expansion, decomposition, multi-query generation, and answering/validation planning.
- v3.8 Retrieval Quality & Knowledge Accuracy: multi-query recall, deterministic rerank, evidence selection, retrieval diagnostics, golden query evaluation, claim/source/freshness/contradiction reports, and external absorption map.
- v3.9 Local Workspace Storage & Memory Lifecycle: local registries, storage usage, dedup/cleanup/retention plans, memory lifecycle, token budget policy, local PDF token reduction, parser backend benchmark, and no-cloud-upload reports.
- v3.10 Local Agent Runtime & Mother/Child Operations: deterministic local runtime smoke, task routing, child KB boundary reports, private/shared memory policy reports, and writeback action contracts.
- v3.11 Golden Demo Acceptance Smoke: real acceptance smoke command, sample coverage, artifact openability, compatibility, and smoke realism reports.
- v3.12 Product Hardening & Local Release Readiness: doctor/diagnostics, command/package/workspace audits, stable error taxonomy, troubleshooting, optional dependency diagnostics, privacy boundary, installer readiness, and v4 RC gate reports.
- Final pre-v4 audit command: `final-pre-v4-audit`, which is intentionally strict and may mark the product blocked until all P0/P1 evidence is resolved.

## Still Under Final Audit

- v4.0 is not released.
- UI Workbench is not merged into Core and must be validated separately for contract drift and product truth.
- BYO cloud and local database backends are future-compatible contracts only, not implemented default storage.
- SaaS, multi-user permissions, platform-hosted user data, and cloud sync are out of scope.
- Real LLM/API/network calls are not required by Core tests and are never default behavior.
- Lifecycle destructive operations remain conservative; cleanup plans are generated, but destructive cleanup is not enabled by default.
- Industrial-scale readiness is still being audited with explicit P0/P1/P2 findings.

## Local Privacy Boundary

Default behavior is local-first:

- no platform-hosted user data
- no hidden upload
- no real LLM/API/network requirement in tests
- LLM is optional assist only
- provider secrets are referenced through environment variables, not stored in package outputs
- BYO cloud/database is future/optional unless a later version implements and tests it

## UI Status

The UI prototype is tracked separately in `kb-forge-skill-ui` on `feature/workbench-ui-prototype`. This Core repo exposes Workbench contracts, but this README does not claim UI integration is complete. Final pre-v4 acceptance must validate UI build/test results and Core/UI contract drift honestly.

## Install

```powershell
python -m pip install -e ".[dev]"
```

Optional local parser extras:

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,web]"
```

## Quickstart

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_quickstart_output
python -m heitang_kb_forge.cli check-contract --package .\tmp_quickstart_output --output .\tmp_contract
python -m heitang_kb_forge.cli kb-index --package .\tmp_quickstart_output --output .\tmp_kb_index
python -m heitang_kb_forge.cli kb-query --package .\tmp_quickstart_output --query "Summarize the package" --output .\tmp_kb_query
python -m heitang_kb_forge.cli rewrite-query --query "summarize it" --output .\tmp_query_plan
python -m heitang_kb_forge.cli plan-retrieval --query "Summarize the package" --purpose answering --package .\tmp_quickstart_output --output .\tmp_retrieval_plan
python -m heitang_kb_forge.cli generate-documents --package .\tmp_quickstart_output --output .\tmp_documents
python -m heitang_kb_forge.cli product-hardening --workspace . --package .\tmp_quickstart_output --output .\tmp_hardening --no-require-v37 --no-require-v38 --no-require-v39 --no-require-v310 --no-require-v311
python -m heitang_kb_forge.cli final-pre-v4-audit --core-repo . --output .\tmp_final_audit
```

Expected build output:

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `quality_report.json`
- `ingest_report.md`

## Documentation

- [Docs Index](docs/DOCS_INDEX.md)
- [Version Matrix](docs/VERSION_MATRIX.md)
- [User Manual](docs/USER_MANUAL.md)
- [Command Reference](docs/COMMAND_REFERENCE.md)
- [Output Report Guide](docs/OUTPUT_REPORT_GUIDE.md)
- [Local Privacy and Security](docs/LOCAL_PRIVACY_SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Golden Demo Guide](docs/GOLDEN_DEMO_GUIDE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Knowledge Ops Guide](docs/KNOWLEDGE_OPS_GUIDE.md)
- [Agent Planning Readiness Guide](docs/AGENT_PLANNING_READINESS_GUIDE.md)
- [Desktop App Guide](docs/DESKTOP_APP_GUIDE.md)
- [Final Target](docs/WORKBENCH_FINAL_TARGET.md)
- [Workbench Version Plan](docs/WORKBENCH_VERSION_PLAN.md)

Machine-readable historical audit reports currently kept at the repository root are intentional evidence files because existing tests and docs reference them directly. See `repository_surface_audit_report.json` after running the final audit.

## Boundaries

HeiTang KB Forge does not by default:

- call real LLM APIs
- call embedding APIs
- write to a vector database
- upload user documents or generated packages
- run external Agent runtimes
- start a real MCP server
- save real user API keys
- provide SaaS multi-tenancy, team permissions, cloud sync, or platform-hosted user data

## License

MIT License. See [LICENSE](LICENSE).
