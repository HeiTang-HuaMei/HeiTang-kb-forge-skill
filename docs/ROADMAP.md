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
- Real lifecycle backend for source registry and incremental updates.
- Local SQLite knowledge store index.
- Real vector store runtime adapters.
- Real Agent Connector examples.
- More downstream format adapters.

## Explicit Non-Scope

- Tool Runtime.
- SaaS multi-tenant platform.
- Permission system.
- CRM / order / product catalog production integrations.
- UI-only private knowledge package format.
- Moving core logic into React or Tauri.
