# Pre-v4 Real Acceptance Blocker Fix Report

- Overall status: blocked
- Ready for v4 RC: False
- Product hardening: pass
- P0 remaining: 1
- P1 needs review: 3

## Items

- P0 rag_vector_index_industrial_readiness_unproven: blocked - Core proves local keyword/index and vector export artifacts, but not real vector DB write/query, production hybrid keyword/vector retrieval, metadata-filtered vector query, rebuild policy, or stale index detection.
- P0 product_hardening_release_readiness_failed: fixed - Product hardening resolver now finds accepted report locations and no critical blockers remain.
- P0 final_pre_v4_gate_still_blocked: needs_review - Final audit remains blocked until validation/CI proof is attached and all remaining P1 decisions are reviewed; not marked ready.
- P1 local_agent_runtime_blocked_by_kb_access_binding: fixed - Generated KB-bound Agent now records manifest package_id and can access its own KB while unauthorized access remains tested.
- P1 product_hardening_contract_drift_false_negative: fixed - Hardening resolves workbench contracts in known contract output directories.
- P1 secret_pattern_scanner_flags_literal_test_patterns: fixed - Secret scanner ignores detector literal definitions and redacts detected values; no hits remain in fixed run.
- P1 knowledge_accuracy_warning_on_conflict_sources: accepted_needs_review - Contradictory verification sources honestly produce status=warning score=0.6715 review_required=True; not forced to pass.
- P1 scanned_pdf_full_ocr_not_proven: accepted_needs_review - Scanned PDF has 120 OCR candidate pages; build used max_ocr_pages=8; full OCR remains limited and not overclaimed.
- P1 optional_live_llm_not_verified_process_env_isolation: accepted_non_blocking_needs_review - Current Codex process did not inherit HEITANG_LLM_* variables; local core still passes without LLM and API key was not printed or committed.

Raw inputs, full chunks, generated documents, API keys, and env scripts remain excluded from commit.
