# Changelog

This changelog is normalized by logical capability versions. Some capabilities were implemented in compressed commits during development, but each logical version is listed separately here.

## v1.2.0

Added Knowledge Ops & Governance Platform:

- Added workspace registry commands: `workspace init`, `workspace register`, `workspace status`.
- Added refresh / staleness detection via `refresh-check`.
- Added review / curation loop via `review-create` and `review-apply`.
- Added evaluation dashboard data export via `eval-record`.
- Upgraded optional Web UI operations views.
- Added publish / export profiles via `publish`.
- Added Agent Planning Readiness outputs via `planning-readiness`.
- Added v1.2 supplementary docs.
- Preserved offline / default behavior.
- No Tool Runtime, no real business integration, no permissions, no SaaS multi-tenancy, and no real external platform API calls.

## v1.1.0

Added Knowledge Runtime & Web MVP:

- Added package versioning and diff.
- Added incremental build / safe reuse.
- Added chunk strategy profiles.
- Added knowledge graph export.
- Added retrieval eval dataset export.
- Added risk labels and source reliability report.
- Added minimal ask runtime with answer report and retrieval trace.
- Added optional Streamlit Web UI MVP.
- Preserved offline default tests.

## v1.0.0

Added Stable Agent Knowledge Supply Chain release:

- Added text-based PDF table extraction.
- Added scanned PDF / image OCR table best-effort.
- Added package validation and readiness reports.
- Added hallucination risk fields.
- Added downstream export formats.
- Added `book_marketing_agent`, `publisher_sales_agent`, and `enterprise_kb_agent`.
- Added optional live provider validation.
- Added v1 stable smoke tests and project documentation.

## v0.9.0

Added Runtime Connector Pack:

- Added OpenAI-compatible LLM provider readiness skeleton.
- Added fake / OpenAI-compatible embedding provider interface.
- Added embedding output files.
- Added local JSON vector export.
- Added enhanced Agent tools config.
- Added runtime connector config and pipeline stages.
- No real API or real vector database writes by default.

## v0.8.3

Added Pipeline workflow:

- Added `pipeline --config`.
- Added `pipeline_report.md`.
- Added `pipeline_manifest.json`.
- Added stage status reporting.
- Preserved `run --config` behavior.

## v0.8.2

Added config-driven execution:

- Added `run --config`.
- Added YAML / YML config support.
- Added config mapping for build, batch, merge, LLM, RAG, Agent Template, and Demo Report.
- Added example config files.

## v0.8.1

Added portfolio demo packages:

- Added product manager agent demo.
- Added shopping guide agent demo.
- Added education tutor agent demo.
- Added output samples for portfolio display.

## v0.8.0

Added Demo / Eval report:

- Added `--demo-report`.
- Added `demo_report.md`.
- Added `demo_manifest.json`.
- Added `eval_summary.json`.
- Added pass / warning / fail readiness status.

## v0.7.2

Added Agent Tool Config standardization:

- Enhanced `tools.yaml`.
- Added runtime_required, input_schema, output_schema, safety_notes, and config fields.
- Added placeholder tools.
- Did not execute tools.

## v0.7.1

Added more Agent Templates:

- Added `book_marketing_agent`.
- Added `publisher_sales_agent`.
- Added `enterprise_kb_agent`.

## v0.7.0

Added Agent Template generation:

- Added `--agent-template`.
- Added `--agent-type`, `--agent-name`, and `--agent-language`.
- Added `agent_profile.yaml`, `system_prompt.md`, `retrieval_config.yaml`, `tools.yaml`, and `eval_cases.jsonl`.

## v0.6.2

Added Vector Export Adapter:

- Added `--vector-export`.
- Added `--vector-store`.
- Added `vector_store_records.jsonl`.
- Added `vector_store_manifest.json`.
- Supported local JSON / fake vector export.
- Did not write to real vector databases by default.

## v0.6.1

Added Embedding Provider adaptation:

- Added `--embedding`.
- Added `--embedding-provider`.
- Added `--embedding-model`.
- Added fake embedding provider.
- Added OpenAI-compatible embedding provider skeleton.
- Added `embeddings.jsonl` and `embedding_manifest.json`.

## v0.6.0

Added RAG export:

- Added `--rag-export`.
- Added `embedding_input.jsonl`.
- Added `retrieval_metadata.jsonl`.
- Added `citation_map.json`.
- Added `rag_manifest.json`.
- Did not call embedding APIs or write real vectors.

## v0.5.3

Added LLM extraction quality evaluation:

- Added `--llm-quality-report`.
- Added `llm_quality_report.json`.
- Added `llm_quality_summary.md`.
- Added citation / metadata / duplicate / empty-output checks.

## v0.5.2

Added LLM Prompt Profile:

- Added `--prompt-profile`.
- Added prompt profile metadata.
- Added prompt profile hash to cache key.
- Added config support for prompt profile.

## v0.5.1

Added LLM Provider Readiness:

- Added provider metadata.
- Added token usage metadata.
- Added cache key handling.
- Added OpenAI-compatible provider readiness skeleton.

## v0.5.0

Added LLM structured extraction:

- Added opt-in `--llm`.
- Added fake provider support.
- Added LLM cards, QA pairs, glossary, frameworks, cases, and metrics.
- Preserved offline default outputs.

## v0.4.3B

Added PDF / OCR table extraction:

- Added text-based PDF table extraction.
- Added scanned PDF / image OCR table best-effort.
- Added fallback-safe table extraction.
- Did not guarantee perfect layout reconstruction.

## v0.4.3

Added DOCX embedded table extraction:

- Added paragraph extraction.
- Added DOCX embedded table extraction.
- Converted DOCX table rows into readable text.

## v0.4.2

Added CSV / TSV / XLSX table ingestion:

- Added structured table parsing.
- Added multi-sheet XLSX support.
- Added header normalization.
- Converted rows into readable text.

## v0.4.1

Added scanned PDF OCR fallback:

- Added fallback when text-based PDF extraction is empty or too short.
- Preserved text-based PDF as the priority path.

## v0.4.0

Added image OCR:

- Added optional OCR support for PNG, JPG, and JPEG.
- OCR text enters the standard pipeline.
- Did not implement image semantic understanding.

## v0.3.1

Added quality report:

- Added `quality_report.json`.
- Added Quality Summary in `ingest_report.md`.
- Added empty / duplicate / coverage checks.
- Added quality score and quality level.

## v0.3.0

Added batch / merge workflow:

- Added batch processing.
- Added same-sequence merge workflow.
- Preserved deterministic package outputs.

## v0.2.0

Added deterministic knowledge package:

- Added stable chunk IDs.
- Added base cards / QA / glossary outputs.
- Added manifest and ingest report.

## v0.1.0

Initial CLI foundation:

- Added Typer CLI foundation.
- Added local build command.
- Added base input/output structure.
- Added UTF-8 output contract.
