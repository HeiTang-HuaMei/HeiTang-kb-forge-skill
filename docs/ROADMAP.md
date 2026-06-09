# Roadmap

This roadmap describes the current main branch direction only. Historical version plans and implementation notes are available through git history and tags.

## Current State

- Core pre-v4 RC readiness: complete for the latest Core P0 proof.
- P1 local Workbench gate: passed for v4 RC readiness.
- Latest Core P0 proof: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- Latest P1 proof: `docs/audits/p1_final_gate_rerun/`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- v4.0 is not released, not tagged, and not started.

## Next Gate: Pre-v4 External Project Registry Pass

The next product gate is a pre-v4 external project registry pass, followed by S/A contract inclusion and then v4.0.0-rc.1 release preparation.

## Later Gate: P2 Productization

[P2 Productization](10_roadmap/P2_PRODUCTIZATION.md) starts only after P1 has evidence. It covers packaging, release notes, publication hygiene, diagnostics polish, and final product acceptance loops.

## Standing Architecture Direction

HeiTang KB Forge remains Skill-first. The UI is a presentation layer, not the Core product engine. OpenClaw, Claude Code, and Codex compatibility remain Agent-facing package surfaces.

## Parser Backend Direction

Current completed parser capability remains verified internal parser, bounded best-effort OCR, and PDF token reduction. external backend candidate and planned adapter status is tracked in [Parser Backend Strategy](03_core_capabilities/PARSER_BACKEND_STRATEGY.md): OpenDataLoader for end-to-end PDF -> Markdown/JSON/RAG-ready parsing, PaddleOCR for OCR foundation, MinerU for document structure understanding and complex layout parsing, and PaddleOCR + MinerU as a planned OCR + document understanding pipeline.

This roadmap adds no parser code, no dependency, no model download, and no external parser execution.

## Non-Scope Until Proven

- v4.0 release or tag
- v4.0 started from this P1 gate
- SaaS multi-tenancy
- team permissions
- cloud sync
- platform-hosted user data
- full external vector database production readiness
- external parser backend adapter completion
- real LLM/API/network dependency in Core tests
