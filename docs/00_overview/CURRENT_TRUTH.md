# Current Truth

Current Core version: `3.12.0-alpha.1`

This is the short current-state entry for GitHub readers. It is intentionally about the current main branch, not historical version planning.

## Gate State

- Core pre-v4 RC readiness: complete for the latest Core P0 proof.
- Latest proof directory: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- Latest root gates: `final_v4_rc_gate_report.json` and `v4_rc_final_gate_report.json`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- Baseline evidence before P0.6 documentation governance: Core main `053a6a6`, GitHub CI run `27140288050` success.

v4.0 is not released, not tagged, and not started. UI full-operation remains blocked.

## Product Positioning

HeiTang KB Forge is a local-first, offline-first Core Skill for converting local source materials into auditable, retrievable, Agent-ready knowledge packages. The Core is headless and Skill-first. UI is a presentation layer and must pass a separate full-operation gate before any full Workbench claim.

## Current Evidence

- Latest Core P0 proof: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- Human-readable final truth: `docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md`
- Capability summary: `docs/00_overview/CAPABILITY_MATRIX.md`
- Documentation governance: `docs/DOCUMENTATION_GOVERNANCE.md`

## Must Not Claim

- v4.0 released or tagged
- full user-operable Workbench
- UI full-operation complete
- external vector database production readiness
- platform-hosted user data as a default
- real LLM/API/network calls as required by Core tests
- saved real user API keys
- SaaS multi-tenancy, team permissions, or cloud sync
