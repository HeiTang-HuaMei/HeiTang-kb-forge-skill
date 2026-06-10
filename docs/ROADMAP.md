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
- Current stable release tag: `v4.0.0`.
- Current release candidate line: `v4.1.0`.

## Current Gate: v4.1.0 Parser/OCR Industrial Release

The current product gate is the `v4.1.0` release candidate: P2.1 parser/OCR backend evidence, Workbench sync, reproducibility, failure-mode coverage, Core/UI validation, release-readiness, CI green, release-check workflow evidence, and no secret/build/raw artifact pollution. The stable `v4.0.0` / v4.0 tag remains untouched.

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
- v4.1.0 release without P2.1 parser/OCR evidence, Workbench sync, validation, and release hygiene
- P2.2 started inside v4.1.0 release hardening
- SaaS multi-tenancy
- team permissions
- cloud sync
- platform-hosted user data
- full external vector database production readiness
- new external parser backend expansion beyond the existing P2.1 adapters
- real LLM/API/network dependency in Core tests
