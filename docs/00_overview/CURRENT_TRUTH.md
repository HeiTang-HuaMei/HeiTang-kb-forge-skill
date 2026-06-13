# Current Truth

Current Core package version: `4.2.0`
Current stable release: `v4.2.0`
Previous stable release: `v4.1.1`

This is the short current-state entry for GitHub readers. It is intentionally about the current main branch, not historical version planning.

## Gate State

- v4.2.0 P2.2 Knowledge-to-Methodology-to-Skill-Suite Industrial Baseline adds evidence windows, methodology extraction, skill candidate planning, Skill Suite hierarchy, Skill Pack export, suite validation, diff, installability, and governance reports.
- v4.1.1 Test Framework Governance remains the P2.2 Entry Gate / Test Governance Stable Baseline.
- P2.1 Parser/OCR Pluggable Backend Runtime is release-hardened from v4.1.0.
- Docling, PaddleOCR, and Unstructured are real opt-in local runtime adapters.
- Builtin parser remains the default fallback.
- Latest P2.1 evidence directory: `docs/audits/p2_1_parser_ocr_backends/`
- Latest live runtime proof: `docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Unstructured stable surface is `.md/.txt`; PDF/DOCX/image extras are future hardening.
- External registry hygiene remains `needs_verification=0`.
- Product Output Surface and External Trend Alignment Gate is registered as governance-only; external trend projects remain future/reference entries with no runtime integration.
- `v4.1.0` remains the historical Parser/OCR stable tag.
- `v4.0.0` remains an untouched historical stable tag.
- `v4.2.0` is the current P2.2 industrial baseline release; P2.3 has not started.

`v4.2.0` is the current stable P2.2 Knowledge-to-Methodology-to-Skill-Suite release after the v4.1.1 Entry Gate. The stable closure is backed by a new Chunked Full Gate, Post-Codex Full Review, CI, Release Check, tag, and GitHub Release evidence.

## Product Positioning

HeiTang KB Forge is a local-first, offline-first Core Skill for converting local source materials into auditable, retrievable, Agent-ready knowledge packages. The Core is headless and Skill-first. UI is a presentation layer and must pass a separate full-operation gate before any full Workbench claim.

HeiTang Knowledge Workbench has four distinct product output surfaces: `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package`. `document_outputs` include Markdown, DOCX / Word, PDF, and PPTX / PowerPoint through the existing `generate-documents` Core capability. Document Outputs are formal product outputs, not audit-report side effects and not covered by Skill Outputs.

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
- Unstructured PDF/DOCX/image support as stable in v4.2.0
- P2.3 started inside v4.2.0
- Anything2Skill, SkillX, or Anthropic Skills / skill-creator integrated as external runtimes, vendored code, providers, accounts, or APIs
- Presenton as an integrated PPT runtime, LongLive as integrated video generation, CodeGraph / Understand Anything as integrated knowledge graph, Claude plugin runtime, or pi-mono runtime
