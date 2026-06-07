# v3.9 Local Workspace Storage & Memory Lifecycle

v3.9 adds a local-first workspace management layer for Core outputs. It keeps existing package outputs backward compatible while adding opt-in registries, storage reports, memory lifecycle contracts, and local document parsing/token-reduction reports.

## Capabilities

- Local workspace registry with package, skill, agent, memory, document, and index registries.
- Storage usage reports with file counts and byte counts by asset type.
- SHA-256 content hash tracking and duplicate recommendations.
- Recommendation-only cleanup, archive, and retention plans. v3.9 never deletes files by default.
- Memory lifecycle contracts for `session_log`, `short_term_memory`, `summary_memory`, `long_term_memory`, `memory_candidates`, `memory_index`, `retention_policy`, `compaction_policy`, and `token_budget_policy`.
- Token budget policy that prevents all-history injection and prefers summary/long-term/index references.
- Local PDF-to-Markdown preprocessing path, parser backend selection, parser benchmark, PDF token reduction estimate, and no-cloud-upload report.

## Local Document Parsing And Token Reduction

Raw PDFs should not be sent wholesale to an LLM by default. v3.9 prefers local parsing into structured Markdown/report outputs, then chunking and retrieval. The LiteDoc benchmark is absorbed as a privacy and token-cost pattern only; LiteDoc code is not integrated or copied.

Parser routing is deterministic:

- Text PDF/simple document: lightweight local parser path.
- Scanned/image PDF: OCR-required marker.
- Complex layout/table/formula document: complex parser route or review-required marker.
- Unknown input: fallback with review-required.

## No Cloud Upload

v3.9 does not upload documents, does not call cloud document APIs, and does not require real LLM/API/network calls in tests. Future `local_db` and `byo_cloud` backends remain contract placeholders only.

## CLI

- `init-workspace`
- `scan-workspace`
- `report-storage`
- `plan-cleanup`
- `plan-memory-lifecycle`
- `estimate-token-budget`
- `preprocess-pdf-markdown`
- `benchmark-parser-backends`
- `report-pdf-token-reduction`

## Reports

Key outputs include `workspace_registry.json`, typed registries, `storage_usage_report.json`, `dedup_report.json`, `cleanup_plan.json`, `memory_lifecycle_report.json`, `memory_compaction_plan.json`, `token_budget_policy.json`, `local_pdf_markdown_report.json`, `parser_backend_benchmark_report.json`, `pdf_token_reduction_report.json`, `no_cloud_upload_report.json`, and `v39_external_absorption_map.json`.
