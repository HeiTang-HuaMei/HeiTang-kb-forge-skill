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

## Explicit Non-Scope

- Tool Runtime.
- SaaS multi-tenant platform.
- Permission system.
- CRM / order / product catalog production integrations.
- UI-only private knowledge package format.
- Moving core logic into React or Tauri.
