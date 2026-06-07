# Final Product Architecture Truth

This document is the short, human-readable truth surface for the current pre-v4.0 Core state. It summarizes what is implemented, partial, future-only, or blocking. Machine-readable evidence remains in `final_v4_rc_gate_report.json` and `docs/audits/local_acceptance/large_bilingual_run/`.

## Current Gate

- Overall status: blocked
- Ready for v4 RC: false
- Remaining P0: `rag_vector_index_industrial_readiness_unproven`
- Blocking P1: `ui_validation_needs_review`
- CI: green for pushed Core commit `766fe79`
- Full local pytest: passed

## Architecture Truth Matrix

| Layer | Current truth | Status |
| --- | --- | --- |
| Input and parsing | Large PDF, DOCX, Markdown/TXT, structured files, and mixed Chinese/English paths are proven. Full scanned PDF OCR is limited and must not be overclaimed. | partial |
| Knowledge package | Local package build, source inventory, metadata, quality gate, and evidence files exist. Universal structure-aware parsing is not fully proven. | partial |
| RAG query planning | Deterministic query rewrite, expansion, decomposition, multi-query generation, and answering/validation planning exist. | implemented |
| RAG vector/hybrid/index | Keyword/local index paths and vector export artifacts exist. Real vector DB write/query, production hybrid keyword/vector retrieval, metadata-filtered vector query, rebuild policy, and stale index detection are not proven. | P0 blocked |
| Retrieval quality and knowledge accuracy | Local rerank, evidence selection, diagnostics, claim/freshness/contradiction/accuracy reports exist. Contradictory sources must produce warning/review, not a false pass. | implemented with review boundary |
| Document generation | Grounded MD/DOCX/PDF/PPTX generation and validation reports exist. | implemented |
| Agent and Skill | Skill package, standalone Agent, KB-bound Agent, local deterministic runtime smoke, KB boundary, mother/child contracts, and memory policy reports exist. Full autonomous tool-calling Agent Runtime is not implemented. | partial |
| Lifecycle | Create/query paths are proven. Update/diff/rebuild/regenerate/refresh are partial. Cleanup/archive remains recommendation-only and non-destructive by default. | partial |
| Storage | `local_workspace` is the implemented default. `local_db` is partial/store-index oriented. BYO cloud/database is future/disabled, not implemented. | partial |
| Security/privacy | Local-first, no hidden upload by default, API key redaction, and no platform-hosted user data are documented and tested. Dynamic runtime network proof and full UI security acceptance remain needs-review. | partial |
| Scale | Synthetic 1500-scale checks exist. Real 1500 books, 1500 KBs, and 1500 Agents are not production-proven. | needs_review |
| UI | Core emits Workbench contracts. Current UI status is `contract_viewer_only`; full user-operable local Workbench is not proven. | blocking P1 |

## Must Not Claim Yet

- v4.0 released or ready
- production vector database readiness
- production hybrid keyword/vector retrieval
- full user-operable local Workbench
- full autonomous tool-calling Agent Runtime
- full scanned PDF OCR proof
- BYO cloud/database implemented
- destructive cleanup enabled by default
- do not claim platform-hosted user data as a default

## Evidence Files

- `final_v4_rc_gate_report.json`
- `v4_rc_final_gate_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/product_architecture_completeness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/rag_vector_index_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/ui_full_operation_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/multi_format_parser_truth_matrix.json`
- `docs/audits/local_acceptance/large_bilingual_run/agent_runtime_capability_truth_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/lifecycle_crud_update_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/llm_provider_and_per_agent_api_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/storage_backend_truth_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/security_threat_model_gap_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/scale_1500_readiness_report.json`
