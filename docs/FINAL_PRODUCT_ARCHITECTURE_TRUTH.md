# Final Product Architecture Truth

This document is the short, human-readable truth surface for the current v4.2.0 Core state. It summarizes what is implemented, partial, future-only, or blocking. Machine-readable evidence remains in `docs/audits/local_acceptance/large_bilingual_run/` for historical large-file acceptance, `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/` for the latest Core P0 after-live-LLM proof, `docs/audits/p2_1_parser_ocr_backends/` for P2.1 Parser/OCR backend release evidence, `docs/audits/p2_2/` for the P2.2 supplemental version plan, and `docs/testing/VALIDATION_GATE_MANIFEST.json` for v4.2.0 release validation.

## Current Gate

- Latest Core P0 gate: ready_for_v4_rc
- Latest Core P0 proof: `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/final_v4_rc_gate_report.json`
- Remaining Core P0: none in the latest pre-v4 P0 proof.
- Blocking P1: none
- Latest P1 final gate: `docs/audits/p1_final_gate_rerun/p1_final_gate_report.json`
- CI: green for the latest Core commit containing the after-live-LLM proof.
- Full local pytest: passed for the latest Core provider-profile and P0 gate work.
- UI validation: Core emits Workbench contracts, P1-RWF-V2 UI consumption remains historical v4 readiness evidence, and P2.1 parser backend matrix evidence is Workbench-visible without static heavy runtime execution claims.
- P2.1 parser/OCR evidence: Docling, PaddleOCR, and Unstructured are real opt-in local runtime adapters; builtin parser fallback is preserved; Unstructured stable surface is `.md/.txt`.
- v4.1.1 test governance: validation gate manifest, changed-file impact selector, validation runner, pytest markers, and obsolete-test pruning register are present as the P2.2 Entry Gate baseline.
- v4.2.0 P2.2 Skill Suite governance: existing knowledge packages can produce evidence windows, methodology maps, skill candidates, Planning / Functional / Atomic hierarchy, routing rules, dependency graph, validation, diff, installability, governance report, and controlled Skill Pack export.
- Historical v4 RC readiness evidence and the v4.1.0 Parser/OCR stable baseline remain attached for audit continuity.
- Historical note: `docs/audits/local_acceptance/large_bilingual_run/` preserves the earlier large-file run where live LLM was still blocked. It must not be used as the latest live-LLM P0 conclusion.

## Architecture Truth Matrix

| Layer | Current truth | Status |
| --- | --- | --- |
| Input and parsing | Large PDF, DOCX, Markdown/TXT, structured files, mixed Chinese/English paths, builtin fallback, and P2.1 optional parser/OCR runtime evidence are present. Full scanned PDF OCR remains limited and must not be overclaimed. | partial with P2.1 runtime adapters |
| Knowledge package | Local package build, source inventory, metadata, quality gate, and evidence files exist. Universal structure-aware parsing is not fully proven. | partial |
| RAG query planning | Deterministic query rewrite, expansion, decomposition, multi-query generation, and answering/validation planning exist. | implemented |
| RAG vector/hybrid/index | Local keyword/index paths, local JSON vector query, hybrid keyword/vector retrieval, metadata filtering, and stale index diagnostics are implemented and tested. Milvus, Pinecone, Qdrant, Chroma, and cloud vector DB adapters remain future/disabled. | implemented locally with external DB future boundary |
| Retrieval quality and knowledge accuracy | Local rerank, evidence selection, diagnostics, claim/freshness/contradiction/accuracy reports exist. Contradictory sources must produce warning/review, not a false pass. | implemented with review boundary |
| Document generation | Grounded MD/DOCX/PDF/PPTX generation and validation reports exist. | implemented |
| Agent and Skill | Legacy Skill package, standalone Agent, KB-bound Agent, local deterministic runtime smoke, KB boundary, mother/child contracts, memory policy reports, and P2.2 Skill Suite generation exist. The P2.2 path builds methodology-backed Planning / Functional / Atomic Skills with routing, dependency graph, validation, diff, installability, governance, and Skill Pack export. Full autonomous tool-calling Agent Runtime is not implemented. | implemented with suite governance boundaries |
| Lifecycle | Create/query paths are proven. Update/diff/rebuild/regenerate/refresh are partial. Cleanup/archive remains recommendation-only and non-destructive by default. | partial |
| Storage | `local_workspace` is the implemented default. `local_db` is partial/store-index oriented. BYO cloud/database is future/disabled, not implemented. | partial |
| Security/privacy | Local-first, no hidden upload by default, API key redaction, and no platform-hosted user data are documented and tested. Dynamic runtime network proof and full UI security acceptance remain needs-review. | partial |
| Scale | Synthetic 1500-scale checks exist. Real 1500 books, 1500 KBs, and 1500 Agents are not production-proven. | needs_review |
| Test governance | Validation gate manifest, changed-file impact selector, dry-run/executable validation runner, pytest markers, obsolete-test pruning register, and token-efficient log policy are present. | v4.1.1 baseline reused as release process |
| UI | Core emits Workbench contracts. P1-RWF-V2 evidence and UI consumption are historical v4 readiness evidence; P2.1 Workbench sync may show backend matrix, evidence, install mode, and limitations without runtime execution controls; P2.2 UI industrial closure shows Knowledge Package -> Evidence -> Methodology -> Candidates -> Hierarchy -> Skill Suite -> Reports -> Export as a static evidence workflow. | v4.2.0 UI/CLI industrial closure |

## Must Not Claim Yet

- v4.0 released from P1 evidence alone
- external vector database production readiness
- Milvus/Pinecone/Qdrant/Chroma implemented
- v4.0 release from the P1 final gate
- full autonomous tool-calling Agent Runtime
- full product-ready v4.0 until the separate UI Full Operation Acceptance Gate passes
- Book-to-Skill completion without real structured Skill package output, on-demand loading, installability reports, and KB/RAG/Agent compatibility proof
- full scanned PDF OCR proof
- BYO cloud/database implemented
- destructive cleanup enabled by default
- Docling, PaddleOCR, or Unstructured bundled in the default install
- Unstructured PDF/DOCX/image support as stable in v4.2.0
- P2.3 started inside v4.2.0
- Anything2Skill, SkillX, or Anthropic Skills / skill-creator integrated as external runtimes, vendored code, providers, accounts, or APIs
- do not claim platform-hosted user data as a default

## Evidence Files

- `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/final_v4_rc_gate_report.json`
- `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/v4_rc_final_gate_report.json`
- `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/live_llm_acceptance_report.json`
- `docs/audits/p1_final_gate_rerun/p1_final_gate_report.json`
- `docs/testing/VALIDATION_GATE_MANIFEST.json`
- `docs/testing/TEST_PRUNING_REGISTER.md`
- Historical earlier run: `docs/audits/local_acceptance/large_bilingual_run/final_v4_rc_gate_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/product_architecture_completeness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/rag_vector_index_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/ui_full_operation_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/ui_full_operation_acceptance_after_core_p0.json`
- `docs/audits/local_acceptance/large_bilingual_run/multi_format_parser_truth_matrix.json`
- `docs/audits/local_acceptance/large_bilingual_run/agent_runtime_capability_truth_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/lifecycle_crud_update_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/llm_provider_and_per_agent_api_readiness_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/storage_backend_truth_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/security_threat_model_gap_report.json`
- `docs/audits/local_acceptance/large_bilingual_run/scale_1500_readiness_report.json`
