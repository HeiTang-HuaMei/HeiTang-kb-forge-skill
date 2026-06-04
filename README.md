# HeiTang KB Forge Skill

[简体中文](README.zh-CN.md) | English

## Overview

`heitang-kb-forge-skill` is an Agent knowledge supply-chain foundation.

It turns multi-format materials into standardized, traceable, searchable, auditable, evaluable, and reusable knowledge asset packages. These packages can be used as the upstream knowledge foundation for downstream RAG systems, Q&A Agents, shopping-guide Agents, education-tutor Agents, product-manager Agents, enterprise knowledge-base Agents, and similar Agent workflows.

The project is offline-first by default. Optional capabilities such as LLM extraction, OCR, RAG export, embedding/vector export, local Agent Runtime MVP, Web UI, live provider validation, and knowledge operations are opt-in.

## Skill-first Architecture

The desktop UI is a presentation layer. The core remains a headless, agent-callable knowledge supply-chain Skill.

Architecture priority:

```text
Core Skill / Python package
> CLI
> Config / Pipeline
> Agent-callable skill interface
> Desktop UI
```

HeiTang KB Forge can be called by OpenClaw, Claude Code, Codex, other Agent frameworks, the local CLI, future Agent Runtime / RAG Runtime, and the desktop UI. All entry points share the same standard knowledge package output contract.

### Headless CLI Usage

```powershell
heitang-kb-forge build --input .\input --output .\output
python -m heitang_kb_forge.cli pipeline --config .\examples\configs\kb_forge.build.yaml
```

### Agent-callable Skill Usage

```text
Agent receives documents
-> calls heitang-kb-forge
-> gets standardized knowledge package
-> uses package for RAG / Q&A / planning / downstream export
```

See `docs/AGENT_INTEGRATION.md` for OpenClaw, Claude Code, Codex, Generic Agent, and MCP-ready integration guidance.

Future Skill interface structure is reserved:

```text
skills/
  heitang-kb-forge-skill/
    SKILL.md
    skill.json
    examples/
    prompts/
```

### Desktop UI as Presentation Layer

```text
Desktop UI
-> calls Python CLI
-> produces the same standard package
```

The desktop app does not move core logic into React or Tauri and does not introduce UI-only package formats.

## What This Project Is

HeiTang KB Forge is responsible for:

- parsing multi-format source materials
- converting them into a standard knowledge package
- preserving source path, chunk id, and citation traces
- producing deterministic local knowledge assets
- generating quality, readiness, risk, and evaluation files
- exporting RAG / Agent-compatible intermediate formats
- generating Agent Templates
- supporting local knowledge package operations and governance

## What This Project Is Not

This project does not provide:

- Tool Runtime
- real business system integration
- CRM / product / order system calls
- permission system
- SaaS multi-tenancy
- production Web deployment
- real publishing API calls
- full Agent Planning execution

## Installation

PowerShell:

    cd HeiTang-kb-forge-skill
    python -m venv .venv
    .venv\Scripts\activate
    pip install -e ".[dev]"

Optional OCR support:

    pip install -e ".[ocr]"

Optional text-based PDF table extraction:

    pip install -e ".[pdf-table]"

Optional Web UI:

    pip install -e ".[web]"

Full optional local capabilities:

    pip install -e ".[all]"

OCR note: the `ocr` extra installs Python packages only. Tesseract OCR is a system dependency, and Simplified Chinese OCR requires `chi_sim.traineddata`.

## Doctor

Check installation and optional environment readiness:

    python -m heitang_kb_forge.cli doctor --output .\doctor_out

`doctor` reports required base checks as pass/fail and optional OCR / PDF table checks as warnings when missing.

## Quick Start

Run the full quickstart:

    .\examples\quickstart\run_quickstart.ps1

Build a knowledge package:

    heitang-kb-forge build --input .\examples\input --output .\examples\output --domain education --mode teaching

Run through Python module:

    python -m heitang_kb_forge.cli build --input .\examples\input --output .\examples\output --domain education --mode teaching

## Standard Output Files

A standard build generates the core knowledge package:

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `ingest_report.md`
- `quality_report.json`

## Supported Input Coverage

Supported source formats include:

- Markdown
- TXT
- text-based PDF
- text-based DOCX
- PNG / JPG / JPEG with optional OCR
- scanned PDF OCR fallback
- CSV / TSV / XLSX structured table files
- DOCX embedded tables
- text-based PDF tables
- scanned PDF / image table OCR best-effort

## Core CLI Examples

RAG export:

    heitang-kb-forge build --input .\input --output .\output --rag-export

Agent Template generation:

    heitang-kb-forge build --input .\input --output .\output --agent-template --agent-type product_manager_agent

Demo report:

    heitang-kb-forge build --input .\input --output .\output --rag-export --agent-template --demo-report

Config-driven run:

    heitang-kb-forge run --config .\examples\configs\kb_forge.build.yaml

Pipeline workflow:

    heitang-kb-forge pipeline --config .\examples\configs\kb_forge.build.yaml

Minimal ask runtime:

    heitang-kb-forge ask --package .\examples\demo_product_manager_agent\output_sample --query "What is this knowledge package for?"

Workspace registry:

    heitang-kb-forge workspace init --workspace .\workspace
    heitang-kb-forge workspace register --workspace .\workspace --package .\output_sample
    heitang-kb-forge workspace status --workspace .\workspace

Refresh check:

    heitang-kb-forge refresh-check --workspace .\workspace

Review and curation:

    heitang-kb-forge review-create --package .\output_sample --output .\review
    heitang-kb-forge review-apply --package .\output_sample --decisions .\review\review_decisions.jsonl --output .\curated_output

Publish profile:

    heitang-kb-forge publish --package .\output_sample --profile generic_rag --output .\publish_output

Planning readiness:

    heitang-kb-forge planning-readiness --package .\output_sample --output .\planning_output

Quality gate:

    heitang-kb-forge build --input .\input --output .\output --quality-gate
    heitang-kb-forge build --input .\input --output .\output --quality-gate-strict

Run manifest:

    heitang-kb-forge build --input .\input --output .\output --run-manifest

Batch hardening:

    heitang-kb-forge batch --input .\input --output .\output --continue-on-error --fail-fast

Desktop utility:

    .\packaging\desktop\dev_tauri.ps1
    .\packaging\desktop\build_tauri.ps1

## Logical Version Capability Index

This section documents the expected unmerged logical version sequence. Some capabilities were implemented in compressed commits during development, but they are listed here as separate logical capability versions for clarity.

### v0.1.0 Core CLI Foundation

- Typer CLI foundation
- local build command
- basic input/output structure
- UTF-8 output contract

### v0.2.0 Deterministic Knowledge Package

- deterministic chunk generation
- stable `chunk_id`
- basic cards / QA / glossary outputs
- manifest and ingest report

### v0.3.0 Batch / Merge Workflow

- batch processing
- same-sequence merge workflow
- stable per-item package outputs
- default offline package generation

### v0.3.1 Quality Report

- `quality_report.json`
- Quality Summary in `ingest_report.md`
- empty / duplicate / coverage checks
- quality score and quality level

### v0.4.0 Image OCR

- optional OCR support for PNG / JPG / JPEG
- OCR text enters the standard clean / chunk / asset pipeline
- no image semantic understanding

### v0.4.1 Scanned PDF OCR Fallback

- scanned PDF OCR fallback
- text-based PDF remains the priority path
- OCR triggers when PDF text extraction is empty or too short

### v0.4.2 CSV / TSV / XLSX Table Ingestion

- structured table file parsing
- multi-sheet XLSX support
- header normalization
- row-to-text conversion

### v0.4.3 DOCX Embedded Table Extraction

- DOCX paragraph extraction
- DOCX embedded table extraction
- table rows converted into readable text

### v0.4.3B PDF / OCR Table Extraction

- text-based PDF table extraction
- scanned PDF / image OCR table best-effort
- fallback-safe table extraction
- no perfect layout reconstruction

### v0.5.0 LLM Structured Extraction

- opt-in `--llm`
- fake provider for local tests
- LLM cards / QA / glossary / frameworks / cases / metrics
- fallback / strict modes

### v0.5.1 LLM Provider Readiness

- provider metadata
- token usage metadata
- cache key handling
- OpenAI-compatible provider readiness skeleton

### v0.5.2 LLM Prompt Profile

- `--prompt-profile`
- prompt profile metadata
- prompt profile hash in cache key
- config-driven prompt profile support

### v0.5.3 LLM Extraction Quality Evaluation

- `--llm-quality-report`
- `llm_quality_report.json`
- `llm_quality_summary.md`
- citation / metadata / duplicate / empty-output checks

### v0.6.0 RAG Export

- `--rag-export`
- `embedding_input.jsonl`
- `retrieval_metadata.jsonl`
- `citation_map.json`
- `rag_manifest.json`

### v0.6.1 Embedding Provider Adaptation

- `--embedding`
- fake embedding provider
- OpenAI-compatible embedding provider skeleton
- `embeddings.jsonl`
- `embedding_manifest.json`

### v0.6.2 Vector Export Adapter

- `--vector-export`
- `--vector-store`
- local JSON vector export
- `vector_store_records.jsonl`
- `vector_store_manifest.json`

### v0.7.0 Agent Template Generation

- `--agent-template`
- `agent_profile.yaml`
- `system_prompt.md`
- `retrieval_config.yaml`
- `tools.yaml`
- `eval_cases.jsonl`

### v0.7.1 More Agent Templates

- `book_marketing_agent`
- `publisher_sales_agent`
- `enterprise_kb_agent`
- expanded business-facing template coverage

### v0.7.2 Agent Tool Config Standardization

- enhanced `tools.yaml`
- runtime_required / input_schema / output_schema
- placeholder tools
- no tool execution

### v0.8.0 Demo / Eval Report

- `--demo-report`
- `demo_report.md`
- `demo_manifest.json`
- `eval_summary.json`
- pass / warning / fail readiness status

### v0.8.1 Portfolio Demo Packages

- product manager demo package
- shopping guide demo package
- education tutor demo package
- output samples for portfolio display

### v0.8.2 Config-driven Execution

- `run --config`
- YAML / YML config support
- build / batch / merge / LLM / RAG / Agent / Demo mapping

### v0.8.3 Pipeline Workflow

- `pipeline --config`
- `pipeline_report.md`
- `pipeline_manifest.json`
- stage status reporting

### v0.9.0 Runtime Connector Pack

- LLM provider readiness
- embedding provider adaptation
- vector export adapter
- Agent tool config standardization
- no real runtime execution by default

### v1.0.0 Stable Agent Knowledge Supply Chain

- complete input coverage expansion
- PDF / OCR table extraction
- package validation / readiness report
- downstream export formats
- optional live provider validation
- stable docs and smoke tests

### v1.1.0 Knowledge Runtime & Web MVP

- package versioning / diff
- incremental build / safe reuse
- chunk strategy profiles
- knowledge graph export
- retrieval eval dataset export
- risk labels
- minimal ask runtime
- optional Streamlit Web UI MVP

### v1.2.0 Knowledge Ops & Governance Platform

- Workspace / Package Registry
- Refresh / Staleness Detection
- Human Review / Curation Loop
- Evaluation Dashboard Data
- Web UI Upgrade
- Publish / Export Profiles
- Agent Planning Readiness Pack

### v1.2.1 Industrial Hardening & Batch Quality

- `--quality-gate` and `--quality-gate-strict`
- package acceptance reports
- optional run manifest and stage trace
- batch run summary, failed item list, and retry manifest
- source hash refresh detection
- batch fail-fast and resource guard options

### v1.2.2 Tauri Desktop Utility

- optional Tauri / React / TypeScript desktop scaffold
- local UI wrapper for build, batch, and pipeline workflows
- Windows EXE packaging scripts
- bilingual UI labels
- no Electron dependency
- no cloud service, vector database, or external Agent platform calls

### v1.2.3 Desktop UI Freeze & Future-Ready Layout

- Skill-first architecture preserved
- desktop UI frozen as a presentation layer
- default zh-CN UI with en-US switching
- dark black/white/gray industrial tool style
- fixed 11-page navigation
- Knowledge Lifecycle, SQLite / Vector Store, Agent Connector, and Retrieval Runtime placeholders
- tiger/cat icon asset split documented

### v1.2.4 Desktop UI Polish

- fixed global locale linkage across TopBar, Sidebar, pages, and Settings
- removed mixed Chinese / English labels from Settings
- separated readonly fields from editable and future-reserved fields
- improved Dashboard, Build, Batch, Lifecycle, Ask, Publish, Planning, and Settings information hierarchy
- kept the 11-page IA unchanged
- preserved Skill-first boundaries and headless CLI usage

### v1.3.0 Knowledge Lifecycle Core

- optional source registry and source change detection
- lifecycle-check command for comparing current sources with an existing package
- incremental update reports for reused, rebuilt, removed, and stale chunks
- update quality gate and quality regression report
- retry manifest and failed source outputs
- lifecycle config block for `run --config` and `pipeline --config`

```powershell
heitang-kb-forge lifecycle-check --input .\sources --package .\output --output .\lifecycle_check
```

```powershell
heitang-kb-forge build --input .\sources --output .\output --lifecycle --update-mode incremental --missing-source-policy mark_stale
```

### v1.4.0 Local Knowledge Store

- optional local SQLite index for generated knowledge packages
- package import and workspace sync
- package list, query, and status commands
- store index export for Agent / ops workflows
- standard knowledge package files remain the source of truth

```powershell
heitang-kb-forge store init --db .\kb_forge_workspace.db
heitang-kb-forge store import-package --db .\kb_forge_workspace.db --package .\output_sample
heitang-kb-forge store export-index --db .\kb_forge_workspace.db --output .\store_export
```

### v1.5.0 Agent RAG Layer

- local retrieve command for packages or the SQLite store
- local ask command with citation-required mode
- retrieval result, trace, citation trace, and answer outputs
- config and pipeline support via `agent_rag`
- no embedding API calls and no vector database writes

```powershell
heitang-kb-forge retrieve --package .\output --query "What is this package about?" --top-k 5 --output .\rag_run
```

```powershell
heitang-kb-forge ask --package .\output --query "What is this package about?" --citation-required --output .\ask_run
```

### v1.6.0 Agent Tool / MCP Interface

- local Agent-callable tool registry
- tool export, list, describe, and invoke commands
- retrieve_knowledge local tool invocation
- MCP readiness config export
- no real Agent deployment and no external Agent platform calls

```powershell
heitang-kb-forge tools export --output .\tool_exports
heitang-kb-forge tools invoke --name retrieve_knowledge --input .\input.json --output .\tool_run
heitang-kb-forge mcp export-config --output .\mcp_config
```

## Current Boundaries

- Offline-first by default
- Optional Web UI is local-only
- Optional live provider validation is explicit and not part of default tests
- no Tool Runtime
- no real business integration
- no CRM / product / order system calls
- no permissions
- no SaaS multi-tenancy
- no real publishing API calls

## License

MIT License. See LICENSE for details.

