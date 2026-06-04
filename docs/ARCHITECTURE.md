# Architecture

## Skill-first Architecture

HeiTang KB Forge is an Agent knowledge supply-chain Skill first. The desktop UI is a presentation layer.

Architecture priority:

```text
Core Skill / Python package
> CLI
> Config / Pipeline
> Agent-callable skill interface
> Desktop UI
```

The core remains headless and callable by OpenClaw, Claude Code, Codex, other Agent frameworks, local CLI users, future Agent Runtime / RAG Runtime, and the desktop UI.

## System Flow

```text
Documents
  -> HeiTang KB Forge Core Skill
  -> CLI / Config / Pipeline
  -> Standard Knowledge Package
  -> Quality Gate / Lifecycle / Export
  -> Agent / RAG / Desktop UI consumption
```

The desktop app is a consumer / controller. It does not own the core engine and does not introduce UI-private package formats.

## Pipeline

```text
source files
-> parser
-> cleaner
-> chunker
-> offline extractor
-> quality report
-> optional LLM
-> optional LLM quality
-> optional RAG export
-> optional embedding / vector export
-> optional Agent Template
-> optional validation / downstream export
```

## Progress and Large-file Performance Layer

v1.6.2 adds an opt-in observability and performance layer around the same parser / cleaner / chunker / extractor pipeline.

```text
source files
-> progress events
-> PDF preflight
-> OCR page selection / cache / resume
-> existing package pipeline
-> performance reports
```

This layer writes standard files such as `progress_events.jsonl`, `pdf_preflight_report.json`, `pdf_page_classification.jsonl`, `ocr_resume_report.md`, and `large_file_performance_report.md`. It does not move core logic into UI, does not create UI-only formats, and does not change default build / batch / pipeline behavior.

## v1.6 Multimodal and Contract Layer

v1.6 adds an opt-in multimodal asset and package contract layer:

```text
source files
-> text package
-> multimodal_assets.jsonl
-> multimodal_evidence_map.json
-> Contract v2 files
-> contract checker
```

This layer exists to preserve evidence, mark review-required assets, and make output structure checkable by downstream Skills and Agents. It is not a visual understanding model and does not claim low-confidence fallback assets as extracted facts.

## Parser Layer

Parsers return plain text. PDF, OCR, DOCX, and table-specific extraction converts structured or visual content into readable text before it enters the existing clean / chunk / extractor pipeline.

## Output Contract

The output contract stays Agent-friendly and file-first:

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `quality_report.json`
- `ingest_report.md`
- `rag_manifest.json`
- `embedding_input.jsonl`
- `retrieval_metadata.jsonl`
- `agent_profile.yaml`
- `retrieval_config.yaml`
- `tools.yaml`
- `eval_cases.jsonl`
- `quality_gate_report.json`
- `package_validation_report.json`
- `publish_manifest.json`

Future lifecycle, store, and connector outputs must remain standard files first. The UI only reads and displays them.

## Agent-callable Skill Direction

Future Skill interface structure is reserved:

```text
skills/
  heitang-kb-forge-skill/
    SKILL.md
    skill.json
    examples/
    prompts/
```

The external Skill capability surface should include:

- process multi-format documents
- generate standardized knowledge packages
- generate quality reports
- generate RAG export
- generate Agent Template
- generate downstream export
- run batch / pipeline workflows
- run lifecycle update
- run quality gate

## Runtime Boundary

Generated Agent Template, RAG, embedding, vector, and downstream files are handoff artifacts. They do not execute tools, deploy agents, write to external vector databases, or call external services by default.

## v1.3.0 Knowledge Lifecycle Layer

The lifecycle layer sits after source ingestion and before downstream review. It tracks source files with `source_registry.json`, detects changed / missing / new sources, writes incremental update reports, and generates retry and quality regression artifacts.

Lifecycle outputs remain standard files. They do not move core logic into the desktop UI, do not require external LLM calls, and do not write to vector databases.

## v1.4.0 Local Knowledge Store

The local knowledge store is a SQLite index over existing packages. It imports package metadata, source registry records, chunks, quality records, risks, runs, publish records, and agent targets.

The store is an optional local index. Standard package files remain the durable source of truth, and the store does not connect to external vector databases or services.

## v1.5.0 Agent RAG Layer

The Agent RAG layer reads package files or the local SQLite store, retrieves relevant local records, writes retrieval and citation traces, and generates an offline answer artifact.

It is a local bridge for Agent consumption. It does not call embedding APIs, does not write to vector databases, and does not deploy real Agents.

## v1.6.0 Agent Tool / MCP Interface

The Agent Tool interface exposes KB Forge capabilities as a local registry, schema, safety policy, and limited local invocation path. MCP readiness exports describe future server integration without starting a server.

This layer keeps the Skill-first boundary intact: core Python package and CLI remain the standard execution layer, while external Agent frameworks consume exported tool metadata or call local commands.
