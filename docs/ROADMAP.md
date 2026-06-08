# Roadmap

This roadmap describes the current main branch direction only. Historical version plans and implementation notes are available through git history and tags.

## Current State

- Core pre-v4 RC readiness: complete for the latest Core P0 proof.
- Latest Core P0 proof: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- v4.0 is not released, not tagged, and not started.
- UI full-operation remains blocked.

## Next Gate: P1 UI Core Parity

The next product gate is [P1 UI Core Parity](10_roadmap/P1_UI_CORE_PARITY.md). It must prove real UI operation for the main Core workflows before any full Workbench claim.

## Later Gate: P2 Productization

[P2 Productization](10_roadmap/P2_PRODUCTIZATION.md) starts only after P1 has evidence. It covers packaging, release notes, publication hygiene, diagnostics polish, and final product acceptance loops.

## Standing Architecture Direction

HeiTang KB Forge remains Skill-first. The UI is a presentation layer, not the Core product engine. OpenClaw, Claude Code, and Codex compatibility remain Agent-facing package surfaces.

## Parser Backend Direction

Current completed parser capability remains verified internal parser, bounded best-effort OCR, and PDF token reduction. external backend candidate and planned adapter status is tracked in [Parser Backend Strategy](03_core_capabilities/PARSER_BACKEND_STRATEGY.md): OpenDataLoader for end-to-end PDF -> Markdown/JSON/RAG-ready parsing, PaddleOCR for OCR foundation, MinerU for document structure understanding and complex layout parsing, and PaddleOCR + MinerU as a planned OCR + document understanding pipeline.

This roadmap adds no parser code, no dependency, no model download, and no external parser execution.

## Non-Scope Until Proven

- v4.0 release or tag
- full user-operable Workbench
- SaaS multi-tenancy
- team permissions
- cloud sync
- platform-hosted user data
- full external vector database production readiness
- external parser backend adapter completion
- real LLM/API/network dependency in Core tests
