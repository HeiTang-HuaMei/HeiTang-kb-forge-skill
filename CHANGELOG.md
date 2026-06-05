# Changelog

## v2.3.0

* Added industrial `batch-run` command
* Added `batch_job_manifest.json`
* Added `batch_item_status.jsonl`
* Added batch failure, performance, quality, contract, and governance summaries
* Added `batch-retry` for failed item retry records
* Added package lineage outputs
* Added curated package generation
* Added governance decision audit logs
* Added update impact outputs for packages, Skills, and Agents
* Added Batch & Governance Center read-only summaries
* Preserved default build / batch / run / pipeline behavior
* No platform distribution or upload adapters

## v2.2.0

* Added master Skill import
* Added master Skill decomposition
* Added capability map and workflow graph outputs
* Added style, strategy, task pattern, boundary, and prompt pattern profiles
* Added derived Skill generation from user-owned knowledge packages
* Added Skill safety check
* Added Skill similarity report
* Added Skill license report
* Preserved default build / batch / run / pipeline behavior

## v2.1.0

* Added opt-in input coverage reporting
* Added enhanced source inventory
* Added lightweight HTML / EPUB / ZIP text ingestion
* Added parser hardening report
* Added rule-based knowledge quality scoring
* Added review workflow and curated chunks
* Added retrieval evaluation cases and result report
* Added evidence benchmark result report
* Added optional mock/fallback LLM quality assist
* Preserved default build / batch / run / pipeline behavior

## v2.0.0

* Added stable Agent knowledge supply-chain foundation
* Added `studio-run`
* Added `stable-check`
* Added stable contract extension readiness
* Added offline `provider-health`
* Added `reliability-score`
* Added `release-package`
* Added v2.0 config and pipeline stages
* Reserved master Skill decomposition learning for v2.2
* Reserved platform export and upload adapters for v2.4
* Preserved default build / batch / run / pipeline behavior

## v1.7.0

* Added knowledge governance command and reports
* Added package diff, lifecycle, conflict, staleness, and review queue outputs
* Added local high-precision retrieval index command
* Added context pack and retrieval trace outputs
* Added Evidence Gate command with allow / refuse / needs_review decisions
* Added mock LLM provider adapter for evidence validation
* Added LLM boundary and hallucination check outputs
* Added v1.7 config example
* Preserved default build / batch / run / pipeline behavior
* No embedding API calls and no vector database writes

## v1.8.0

* Added Skill Package Generator
* Added SKILL.md and skill_manifest.yaml generation
* Added answer, citation, boundary, refusal, style, and evidence policy rule files
* Added Skill Validation and benchmark outputs
* Added Agent Package Generator
* Added soul.md, role.md, system_prompt.md, agent_profile.yaml, tool_config.yaml, retrieval_config.yaml, memory_policy.md, safety_boundary.md, and launch_checklist.md
* Added opt-in mock LLM-assisted Skill and Agent generation
* Added v1.8 config and pipeline stages
* Preserved default build / batch / run / pipeline behavior
* No real Agent Runtime, Tool Runtime, vector database, or required LLM API

## v1.9.0

* Added Portable Local Workspace
* Added package, skill, and agent registries
* Added knowledge-skill-agent relationship graph
* Added provider registry without API key storage
* Added prompt profile registry
* Added LLM call audit import
* Added workspace import, export, search, and health check commands
* Added Local Workspace UI v1 read-only summaries
* Preserved default build / batch / run / pipeline behavior

This changelog is normalized by logical capability versions. Some capabilities were implemented in compressed commits during development, but each logical version is listed separately here.

## v1.6

Completed Real-world Ingestion & Knowledge Package Closure:

- Added opt-in multimodal knowledge asset package.
- Added `multimodal_assets.jsonl`.
- Added `multimodal_evidence_map.json`.
- Added `multimodal_report.md`.
- Added PPT/PPTX slide asset fallback and optional slide text chunks.
- Added image / chart / diagram / mindmap / formula best-effort asset preservation.
- Added Knowledge Package Contract v2 support.
- Added `evidence_map.json`, `source_inventory.json`, and `quality_report.md` for Contract v2 packages.
- Added `check-contract` CLI.
- Added `contract_check_result.json` and `contract_check_report.md`.
- Added multimodal and contract config blocks.
- Added multimodal and contract stages in pipeline reports.
- Added minimal Knowledge Package Builder UI v1 result viewer.
- Added bilingual v1.6 documentation and traceability docs.
- Preserved default build / batch / run / pipeline behavior.

## v1.6.2

Added Large File Progress & OCR Acceleration:

- Added progress visualization for build, batch, and pipeline workflows.
- Added `--progress`, `--progress-jsonl`, `--progress-log`, and `--verbose`.
- Added `progress_events.jsonl`.
- Added large-file profiles with `--profile fast|production`.
- Added OCR page control options including `--ocr-mode`, `--max-ocr-pages`, and `--ocr-pages`.
- Added OCR worker, scale, timeout, language, cache, and resume controls.
- Added `pdf_preflight_report.json`.
- Added `pdf_page_classification.jsonl`.
- Added `ocr_cache_manifest.json`.
- Added `ocr_failed_pages.jsonl`.
- Added `ocr_resume_report.md`.
- Added `large_file_performance_report.md`.
- Added performance config support for `run --config` and `pipeline --config`.
- Added performance stages in pipeline reports.
- Preserved default build / batch / pipeline behavior when progress and performance options are not enabled.

## v1.6.1

Added Skill Installability & Agent Integration Pack:

- Added standard SKILL.md content for Agent-callable usage.
- Added skill.json metadata.
- Added doctor command.
- Added doctor_report.json and doctor_report.md.
- Added installation, quickstart, OCR setup, and Agent integration docs.
- Added quickstart example package input and PowerShell runner.
- Added smoke scripts for quickstart and Agent flow.
- Added pyproject `all` optional extra.
- Documented Tesseract and chi_sim as system OCR requirements.
- Preserved Skill-first and CLI-first boundaries.
- No EXE, sidecar, installer, auto-update, or UI feature work.

## v1.6.0

Added Agent Tool / MCP Interface Core:

- Added tools export command.
- Added tools list and describe commands.
- Added local tools invoke command.
- Added retrieve_knowledge invocation support.
- Added tool_registry.yaml.
- Added tool_manifest.json.
- Added agent_tool_schema.json.
- Added tool_safety_policy.md.
- Added MCP config export.
- Added mcp_server_config.yaml.
- Added mcp_tools_manifest.json.
- No real Agent deployment.
- No external Agent platform calls.

## v1.5.0

Added Agent RAG Layer:

- Added retrieve command.
- Added package-based local retrieval.
- Added store-based local retrieval.
- Added ask support for citation-required local answers.
- Added retrieval_result.json.
- Added retrieval_trace.json.
- Added citation_trace.json.
- Added answer.md and answer_report.json for Agent RAG runs.
- Added agent_rag config block support.
- Added Agent RAG stages in pipeline reports.
- No embedding API calls.
- No vector database writes.

## v1.4.0

Added Local Knowledge Store & Package Index:

- Added local SQLite store commands.
- Added package import into store index.
- Added workspace sync for package directories.
- Added package listing and query commands.
- Added package status command.
- Added store index export files.
- Added store config block support.
- Added local store stages in pipeline reports.
- Preserved standard knowledge package files.
- Did not add external database or vector database writes.

## v1.3.0

Added Knowledge Lifecycle Core:

- Added source registry generation.
- Added lifecycle-check command.
- Added source change detection reports.
- Added changed / missing / new source JSONL outputs.
- Added incremental update reports.
- Added reused / rebuilt / removed / stale chunk reports.
- Added removed source impact report.
- Added update quality gate report.
- Added quality regression report.
- Added failed sources and retry manifest outputs.
- Added lifecycle config block support.
- Added lifecycle stages in pipeline reports.
- Preserved default build / batch / pipeline behavior when lifecycle is not enabled.

## v1.2.4

Added Desktop UI Polish:

- Fixed global locale linkage across TopBar, Sidebar, pages, and Settings.
- Replaced mixed Settings labels with i18n-driven labels.
- Added unified status badge variants.
- Added structured empty states and run logs.
- Distinguished editable, readonly, disabled, and future-reserved fields.
- Improved Dashboard, Build, Batch, Workspace, Lifecycle, Quality, Package Detail, Ask, Publish, Planning, and Settings hierarchy.
- Preserved fixed 11-page information architecture.
- Preserved Skill-first and headless CLI boundaries.

## v1.2.3

Added Desktop UI Freeze & Future-Ready Layout:

- Preserved Skill-first architecture.
- Kept Desktop UI as presentation layer.
- Added fixed 11-page desktop information architecture.
- Added default zh-CN UI with en-US switching.
- Added dark black/white/gray industrial desktop styling.
- Added Knowledge Lifecycle placeholders.
- Added SQLite / Vector Store / Agent Connector placeholders.
- Added tiger app icon and cat small icon asset split.
- Added UI architecture, i18n, and icon guideline docs.
- Did not move Python core logic into React or Tauri.

## v1.2.2

Added Tauri Desktop Utility scaffold:

- Added optional Tauri / React / TypeScript desktop app under `desktop/tauri`.
- Added local UI wrapper for build, batch, and pipeline workflows.
- Added bilingual English / Chinese UI labels.
- Added Windows development and build scripts under `packaging/desktop`.
- Added Desktop App Guide.
- Did not add Electron.
- Did not change Python CLI behavior.
- Did not call cloud services, vector databases, or external Agent platforms.

## v1.2.1

Added Industrial Hardening & Batch Quality:

- Added package quality gate via `--quality-gate`.
- Added strict package blocking via `--quality-gate-strict`.
- Added package acceptance reports.
- Added optional run manifest and stage trace via `--run-manifest`.
- Added batch run summary, failed item JSONL, and retry manifest.
- Added batch fail-fast and resource guard options.
- Added source file hash tracking for workspace registry.
- Added refresh detection for changed source hashes and stale packages.
- Preserved default build / batch behavior.

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
