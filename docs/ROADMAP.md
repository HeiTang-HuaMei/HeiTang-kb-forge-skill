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

# v1.8 Skill and Agent Package Generation

v1.8 closes the delivery loop from knowledge package to Skill Package to Agent Package. It adds local generation, validation, benchmark cases, optional mock LLM assistance, and UI previews without adding a real Agent Runtime.

# v1.9 Portable Local Workspace

v1.9 upgrades the project into a local Agent knowledge asset workspace with registries, relationship graph, provider registry, prompt profile registry, LLM call audit, import/export, and health check.

# v2.0 Stable Knowledge Supply Chain Foundation

v2.0 closes the v1.6-v1.9 capabilities into a stable Agent knowledge supply-chain foundation. It focuses on studio-run, stable-check, provider-health, reliability-score, release-package, extension readiness, and stable bilingual documentation.

v2.0 reserves future extension points only. Master Skill decomposition learning, derived Skill generation, and platform distribution are documented as planned capabilities, not implemented v2.0 features.

# v2.1 Knowledge Reliability and Input Hardening

v2.1 strengthens the knowledge foundation with opt-in input coverage, parser hardening, enhanced source inventory, knowledge quality scoring, review workflow, retrieval evaluation, evidence benchmark, and mock/fallback LLM quality assist.

v2.1 remains offline-first and does not make a real LLM mandatory.

# v2.2 Industrial Master Skill Learning

v2.2 is planned to formally implement master Skill and excellent Skill decomposition learning. The target is to analyze Skill structure, task patterns, workflow, style profile, boundary rules, safety constraints, similarity risk, and license status, then combine those learned patterns with the user's own knowledge package to generate derived Skills.

This is not Skill copying. v2.2 should learn reusable structure and workflow patterns while preserving safety, attribution, and user-owned knowledge scope.

v2.2 implementation outputs include `master_skill_inventory.json`, `skill_decomposition.json`, `skill_capability_map.json`, `skill_workflow_graph.json`, profile YAML files, `derived_skill_package`, safety reports, similarity reports, and license reports.

# v2.4 Skill Distribution and Platform Publishing

v2.4 is planned to implement platform export and upload-adapter preparation for OpenClaw, XHS, Codex, Claude Code, MCP, generic packages, and local registry packages.

v2.4 should generate platform manifests, install guides, upload checks, and mock publish results only. It must not call real platform accounts, run real Agent platforms, start a real MCP server, or upload to XHS automatically.

v2.4 implementation scope is local platform distribution output generation, upload readiness checks, and mock publish records. v2.5 / v2.6 / v2.9 remain planned.

# v2.3 Industrial Batch And Knowledge Governance

v2.3 implements industrial batch job manifests, item status tracking, retry records, batch summaries, package lineage, curated package generation, governance decision logs, update impact reports, and a read-only Batch & Governance Center direction.

v2.3 does not implement platform export, platform upload, real Agent runtime, real MCP server, SaaS collaboration, or external publishing APIs. Those remain outside v2.3; platform export and upload adapters are reserved for v2.4.

# v2.3 Checkpoint Fill

The checkpoint fill closes partial v2.2 industrial gaps with enhanced Skill template files, Agent compatibility stubs, static workspace refresh, offline provider readiness, prompt profile versioning, and Studio v2.2 local summaries.

These additions are local file outputs. They do not implement v2.4 platform distribution, XHS packaging/upload, OpenClaw export, MCP export, or mock publish.
