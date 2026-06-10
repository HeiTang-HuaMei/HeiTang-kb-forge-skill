# Current Truth

Current Core package version: `4.1.1`
Current release line: `v4.1.1`
Latest stable release: `v4.1.0`

This is the short current-state entry for GitHub readers. It is intentionally about the current main branch, not historical version planning.

## Gate State

- v4.1.1 Test Framework Governance adds a validation gate manifest, changed-file impact selector, validation runner, pytest markers, and obsolete-test pruning register.
- P2.1 Parser/OCR Pluggable Backend Runtime is release-hardened from v4.1.0.
- Docling, PaddleOCR, and Unstructured are real opt-in local runtime adapters.
- Builtin parser remains the default fallback.
- Latest P2.1 evidence directory: `docs/audits/p2_1_parser_ocr_backends/`
- Latest live runtime proof: `docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Unstructured stable surface is `.md/.txt`; PDF/DOCX/image extras are future hardening.
- External registry hygiene remains `needs_verification=0`.
- `v4.1.0` remains the historical Parser/OCR stable tag.
- `v4.0.0` remains an untouched historical stable tag.
- P2.2 Skill Governance has not started in this release.

`v4.1.1` is the current Test Framework Governance release line after v4.1.0 Parser/OCR industrial release hardening. It is not a stable tag until Chunked Full Gate, tag, release, and release-check evidence are complete.

## Product Positioning

HeiTang KB Forge is a local-first, offline-first Core Skill for converting local source materials into auditable, retrievable, Agent-ready knowledge packages. The Core is headless and Skill-first. UI is a presentation layer and must pass a separate full-operation gate before any full Workbench claim.

## Current Evidence

- Latest Core P0 proof: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- Latest P1 final gate re-run proof: `docs/audits/p1_final_gate_rerun/`
- Latest P2.1 parser/OCR proof: `docs/audits/p2_1_parser_ocr_backends/`
- Human-readable final truth: `docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md`
- Capability summary: `docs/00_overview/CAPABILITY_MATRIX.md`
- Documentation governance: `docs/DOCUMENTATION_GOVERNANCE.md`

## Must Not Claim

- stable v4.0.0 released without rc.1 acceptance and hardening evidence
- stable v4.0.0 released from the P1 gate alone
- stable tag or release created by the P1 gate alone
- external vector database production readiness
- platform-hosted user data as a default
- real LLM/API/network calls as required by Core tests
- saved real user API keys
- SaaS multi-tenancy, team permissions, or cloud sync
- bundled Docling/PaddleOCR/Unstructured dependencies by default
- static Workbench controls that imply local heavy runtime execution
- Unstructured PDF/DOCX/image support as stable in v4.1.1
- P2.2 started inside v4.1.1
