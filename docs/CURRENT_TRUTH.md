# Current Truth

Current Core package version: `4.1.0`
Current stable release: `v4.1.0`

HeiTang KB Forge Skill is an offline-first Agent Knowledge Supply Chain Core. It turns local source materials into standardized, traceable, searchable, auditable, and reusable knowledge assets for RAG, verification, document generation, structured Skill packages, and local Agent workflows.

## Current Gate

- P2.1 Parser/OCR Pluggable Backend Runtime: release-hardened for v4.1.0.
- Docling, PaddleOCR, and Unstructured: real opt-in local runtime adapters, dependency-gated and not bundled.
- Builtin parser: preserved default fallback.
- Latest P2.1 proof: `docs/audits/p2_1_parser_ocr_backends/`
- Latest live runtime acceptance: `docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Unstructured stable surface: `.md/.txt`; PDF/DOCX/image extras are future hardening.
- External registry hygiene remains `needs_verification=0`.
- `v4.0.0` remains an untouched historical stable tag.
- P2.2 Skill Governance has not started in this release hardening task.

The detailed canonical current-truth page is [00_overview/CURRENT_TRUTH.md](00_overview/CURRENT_TRUTH.md).

## Read Next

- [Capability Matrix](CAPABILITY_MATRIX.md)
- [AIGC Book Content Pipeline](AIGC_BOOK_CONTENT_PIPELINE.md)
- [Final Product Architecture Truth](FINAL_PRODUCT_ARCHITECTURE_TRUTH.md)
