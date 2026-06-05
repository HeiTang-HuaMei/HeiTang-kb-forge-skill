# Roadmap

## Current Direction

HeiTang KB Forge remains a Skill-first Agent knowledge supply-chain foundation. Desktop UI work is a local presentation layer, not a replacement for the Python package, CLI, config runner, or pipeline runner.

## v1.2.3

Desktop UI Freeze & Future-Ready Layout:

- fixed 11-page desktop IA
- default zh-CN with en-US switching
- dark black/white/gray desktop tool style
- Knowledge Lifecycle placeholder
- SQLite / Vector Store placeholder
- Agent Connector / Retrieval Runtime placeholder
- Skill-first architecture docs

## Future Candidates

- OpenClaw / Claude Code / Codex Skill packaging.
- `skills/heitang-kb-forge-skill/` interface files.
- Local SQLite knowledge store index.
- Real vector store runtime adapters.
- Real Agent Connector examples.
- More downstream format adapters.

## v1.3.0 Completed

- Source registry generation.
- Source change detection.
- Incremental update reporting.
- Missing source stale marking.
- Update quality gate report.
- Retry manifest generation.

## v1.4.0 Completed

- Local SQLite store initialization.
- Package import into a local index.
- Workspace package sync.
- Package list, query, and status commands.
- Store index export.

## v1.5.0 Completed

- Local retrieve command.
- Package and store retrieval sources.
- Citation trace generation.
- Citation-required ask mode.
- Agent RAG config and pipeline stages.

## v1.6.0 Completed

- Local Agent tool registry.
- Tool export, list, describe, and invoke commands.
- retrieve_knowledge local invocation.
- Tool safety policy output.
- MCP readiness config export.

## v1.6.1 Completed

- Skill installability metadata.
- Doctor command.
- Installation, quickstart, OCR setup, and Agent integration docs.
- Quickstart and smoke scripts.

## v1.6.2 Completed

- Progress visualization for build / batch / pipeline.
- JSONL progress event output.
- Fast / production performance profile.
- OCR page selection, worker, timeout, scale, cache, and resume controls.
- PDF preflight and page classification reports.
- Large file performance report.

## v1.6 Closure Completed

- Multimodal knowledge assets.
- Multimodal evidence map.
- Multimodal report.
- Knowledge Package Contract v2.
- Contract checker.
- Knowledge Package Builder UI v1 result viewer.
- Bilingual v1.6 documentation and traceability.

## Explicit Non-Scope

- Tool Runtime.
- SaaS multi-tenant platform.
- Permission system.
- CRM / order / product catalog production integrations.
- UI-only private knowledge package format.
- Moving core logic into React or Tauri.
# v1.7 Reliable Knowledge Governance

v1.7 adds opt-in knowledge governance, high-precision local retrieval, Evidence Gate, and a minimal LLM provider adapter for evidence validation. These layers are designed to keep HeiTang KB Forge skill-first and headless while supporting later Agent/RAG runtimes.
