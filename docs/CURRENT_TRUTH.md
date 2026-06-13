# Current Truth

Current Core package version: `4.2.0`
Current stable release: `v4.2.0`
Previous stable release: `v4.1.1`

HeiTang KB Forge Skill is an offline-first Agent Knowledge Supply Chain Core. It turns local source materials into standardized, traceable, searchable, auditable, and reusable knowledge assets for RAG, verification, document generation, structured Skill packages, and local Agent workflows.

## Product Output Surfaces

The product output surface is four-part and must stay explicit:

- `knowledge_package`
- `document_outputs`
- `skill_outputs`
- `agent_creation_package`

`document_outputs` are a formal HeiTang Knowledge Workbench product capability, not an audit-report side effect and not covered by the Knowledge-to-Skill route. They include Markdown, DOCX / Word, PDF, and PPTX / PowerPoint. The existing `generate-documents` command remains recognized as `existing_core_capability`.

## Current Gate

- v4.2.0 P2.2 Knowledge-to-Methodology-to-Skill-Suite Industrial Baseline: evidence windows, methodology extraction, skill candidate planning, Planning / Functional / Atomic Skill Suite hierarchy, Skill Pack export, suite validation, diff, installability, and governance reports.
- v4.1.1 Test Framework Governance remains the P2.2 Entry Gate / Test Governance Stable Baseline.
- P2.1 Parser/OCR Pluggable Backend Runtime: release-hardened in v4.1.0 and preserved through v4.2.0.
- Docling, PaddleOCR, and Unstructured: real opt-in local runtime adapters, dependency-gated and not bundled.
- Builtin parser: preserved default fallback.
- Latest P2.1 proof: `docs/audits/p2_1_parser_ocr_backends/`
- Latest live runtime acceptance: `docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Unstructured stable surface: `.md/.txt`; PDF/DOCX/image extras are future hardening.
- External registry hygiene remains `needs_verification=0`.
- Product Output Surface and External Trend Alignment Gate is registered as governance-only: future/reference external projects remain `not_integrated`, and Document Outputs remain first-class product outputs.
- `v4.1.0` remains the historical Parser/OCR stable tag.
- `v4.0.0` remains an untouched historical stable tag.
- `v4.1.1` remains the historical P2.2 Entry Gate / Test Governance Stable Baseline.
- `v4.2.0` is the current P2.2 industrial baseline release; P2.3 has not started.

The detailed canonical current-truth page is [00_overview/CURRENT_TRUTH.md](00_overview/CURRENT_TRUTH.md).

## Read Next

- [Capability Matrix](CAPABILITY_MATRIX.md)
- [AIGC Book Content Pipeline](AIGC_BOOK_CONTENT_PIPELINE.md)
- [Final Product Architecture Truth](FINAL_PRODUCT_ARCHITECTURE_TRUTH.md)
