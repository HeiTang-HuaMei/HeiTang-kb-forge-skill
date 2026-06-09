# Current Truth

Current Core package version: `4.0.0rc1`
Current release candidate: `v4.0.0-rc.1`

This is the short current-state entry for GitHub readers. It is intentionally about the current main branch, not historical version planning.

## Gate State

- Core pre-v4 RC readiness: complete for the latest Core P0 proof.
- P1 local Workbench final gate re-run: passed for v4 RC readiness.
- Latest P1 proof directory: `docs/audits/p1_final_gate_rerun/`
- Latest proof directory: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- Latest root gates: `final_v4_rc_gate_report.json` and `v4_rc_final_gate_report.json`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- Pre-v4 External Project Registry complete.
- S/A Contract Inclusion complete.
- Baseline evidence before P0.6 documentation governance: Core main `053a6a6`, GitHub CI run `27140288050` success.

`v4.0.0-rc.1` is the current release candidate preparation target. Stable `v4.0.0` is not released until rc.1 acceptance and hardening pass.

## Product Positioning

HeiTang KB Forge is a local-first, offline-first Core Skill for converting local source materials into auditable, retrievable, Agent-ready knowledge packages. The Core is headless and Skill-first. UI is a presentation layer and must pass a separate full-operation gate before any full Workbench claim.

## Current Evidence

- Latest Core P0 proof: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- Latest P1 final gate re-run proof: `docs/audits/p1_final_gate_rerun/`
- Human-readable final truth: `docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md`
- Capability summary: `docs/00_overview/CAPABILITY_MATRIX.md`
- Documentation governance: `docs/DOCUMENTATION_GOVERNANCE.md`

## Must Not Claim

- stable v4.0.0 released before rc.1 acceptance
- stable v4.0.0 released from the P1 gate alone
- stable tag or release created by the P1 gate alone
- external vector database production readiness
- platform-hosted user data as a default
- real LLM/API/network calls as required by Core tests
- saved real user API keys
- SaaS multi-tenancy, team permissions, or cloud sync
