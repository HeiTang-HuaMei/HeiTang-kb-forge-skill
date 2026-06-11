# Roadmap

This roadmap describes the current main branch direction only. Historical version plans and implementation notes are available through git history and tags.

## Current State

- Core pre-v4 RC readiness: complete for the latest Core P0 proof.
- P1 local Workbench gate: passed for v4 RC readiness.
- Latest Core P0 proof: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- Latest P1 proof: `docs/audits/p1_final_gate_rerun/`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- Pre-v4 External Project Registry complete.
- S/A Contract Inclusion complete.
- Current stable release: `v4.2.0`.
- Previous stable release tag: `v4.1.1`.
- Historical stable release tag: `v4.0.0`.

## Current Stable Gate: v4.2.0 P2.2 Industrial Baseline

The current stable product gate is the `v4.2.0` P2.2 Knowledge-to-Methodology-to-Skill-Suite Industrial Baseline. Existing knowledge asset packages can flow through evidence windows, methodology extraction, skill candidate planning, Planning / Functional / Atomic Skill hierarchy, routing rules, dependency graph, Skill Pack export, validation, diff, installability, governance, and UI/CLI industrial closure. The existing `v4.0.0`, `v4.1.0`, and `v4.1.1` tags remain untouched.

## P2.2 Entry Gate and Current Baseline

`v4.1.1` is the P2.2 Entry Gate / Test Governance Stable Baseline. It is not part of P2.2; it was the required gate before v4.2 / P2.2 feature work could start and is now fulfilled.

Version relationship:

- `v4.1.0` = Parser/OCR Stable Baseline
- `v4.1.1` = P2.2 Entry Gate / Test Governance Stable Baseline
- `v4.2.0 / P2.2` = Knowledge-to-Methodology-to-Skill-Suite Industrial Baseline

P2.2 feature work started only after v4.1.1 stable release completed: Core/UI release-truth closure, Core/UI CI green, Core/UI Release Check green, v4.1.1 tag / GitHub Release, and Workspace handoff/status sync. v4.2.0 carries P2.2 business capability; P2.3 has not started.

## Later Gate: P2 Productization

[P2 Productization](10_roadmap/P2_PRODUCTIZATION.md) starts only after P1 has evidence. It covers packaging, release notes, publication hygiene, diagnostics polish, and final product acceptance loops.

## Standing Architecture Direction

HeiTang KB Forge remains Skill-first. The UI is a presentation layer, not the Core product engine. OpenClaw, Claude Code, and Codex compatibility remain Agent-facing package surfaces.

## Parser Backend Direction

Current completed parser capability includes the builtin fallback plus opt-in local runtime adapters for Docling, PaddleOCR, and Unstructured. The default parser truth remains verified internal parser, bounded best-effort OCR, and PDF token reduction. P2.1 release evidence is indexed at `docs/audits/p2_1_parser_ocr_backends/`. Unstructured is stable only for `.md/.txt`; broader PDF/DOCX/image surfaces remain future hardening. OpenDataLoader for PDF -> Markdown/JSON/RAG-ready packaging, MinerU, and PaddleOCR + MinerU as an OCR + document understanding pipeline remain external backend candidate / planned adapter only.

This roadmap adds no new parser backend beyond the existing P2.1 Docling/PaddleOCR/Unstructured runtime integrations.

## Non-Scope Until Proven

- stable v4.0.0 release without rc.1 acceptance and hardening evidence
- stable v4.0.0 tag without release-check evidence
- v4.1.1 release without test governance manifest, impacted gate selection, validation, and release hygiene
- P2.2 started inside v4.1.1 release hardening
- P2.3 started inside v4.2.0 release closure
- SaaS multi-tenancy
- team permissions
- cloud sync
- platform-hosted user data
- full external vector database production readiness
- new external parser backend expansion beyond the existing P2.1 adapters
- real LLM/API/network dependency in Core tests
