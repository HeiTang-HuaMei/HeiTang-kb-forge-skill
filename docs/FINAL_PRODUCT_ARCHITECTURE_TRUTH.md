# Final Product Architecture Truth

This document is the short, human-readable truth surface for the current pre-v4.0 Core state. It summarizes what is implemented, partial, future-only, or blocking. Machine-readable evidence remains in `final_v4_rc_gate_report.json` and `docs/audits/local_acceptance/large_bilingual_run/`.

## Current Gate

- Overall status: ready_for_v4_rc
- Ready for v4 RC: true
- Remaining P0: none
- Blocking P1: none
- CI: green for pushed Core commit `97a6bf9`
- Full local pytest: passed
- UI validation: Flutter analyze/test/build-web passed for frozen UI commit `24dfa2b`

## Architecture Truth Matrix

| Layer | Current truth | Status |
| --- | --- | --- |
| Input and parsing | Large PDF, DOCX, Markdown/TXT, structured files, and mixed Chinese/English paths are proven. Full scanned PDF OCR is limited and must not be overclaimed. | partial |
| Knowledge package | Local package build, source inventory, metadata, quality gate, and evidence files exist. Universal structure-aware parsing is not fully proven. | partial |
| RAG query planning | Deterministic query rewrite, expansion, decomposition, multi-query generation, and answering/validation planning exist. | implemented |
| RAG vector/hybrid/index | Local keyword/index paths, local JSON vector query, hybrid keyword/vector retrieval, metadata filtering, and stale index diagnostics are implemented and tested. Milvus, Pinecone, Qdrant, Chroma, and cloud vector DB adapters remain future/disabled. | implemented locally with external DB future boundary |
| Retrieval quality and knowledge accuracy | Local rerank, evidence selection, diagnostics, claim/freshness/contradiction/accuracy reports exist. Contradictory sources must produce warning/review, not a false pass. | implemented with review boundary |
| Document generation | Grounded MD/DOCX/PDF/PPTX generation and validation reports exist. | implemented |
| Agent and Skill | Skill package, standalone Agent, KB-bound Agent, local deterministic runtime smoke, KB boundary, mother/child contracts, and memory policy reports exist. Full autonomous tool-calling Agent Runtime is not implemented. | partial |
| Lifecycle | Create/query paths are proven. Update/diff/rebuild/regenerate/refresh are partial. Cleanup/archive remains recommendation-only and non-destructive by default. | partial |
| Storage | `local_workspace` is the implemented default. `local_db` is partial/store-index oriented. BYO cloud/database is future/disabled, not implemented. | partial |
| Security/privacy | Local-first, no hidden upload by default, API key redaction, and no platform-hosted user data are documented and tested. Dynamic runtime network proof and full UI security acceptance remain needs-review. | partial |
| Scale | Synthetic 1500-scale checks exist. Real 1500 books, 1500 KBs, and 1500 Agents are not production-proven. | needs_review |
| UI | Core emits Workbench contracts. Frozen UI commit `24dfa2b` passes Flutter analyze/test/build-web for the contract-viewer scope. Full user-operable local Workbench is still not claimed. | validated contract-viewer scope |

## Must Not Claim Yet

- v4.0 released or ready
- external vector database production readiness
- Milvus/Pinecone/Qdrant/Chroma implemented
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
