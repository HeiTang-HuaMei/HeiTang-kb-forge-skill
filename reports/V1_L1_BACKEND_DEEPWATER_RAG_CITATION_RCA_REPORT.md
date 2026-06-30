# V1 L1 Backend Deepwater RAG Citation RCA Report

Generated: 2026-06-30

## 1. Scope

This report records the Phase 4 RCA for RAG refusal, citation, and source trace behavior.

It does not modify `capability_chain_status.json`, does not push, does not tag, does not release, and does not make a Final Owner Review decision.

## 2. Failure Summary

Initial failure class:

P1

Observed issue:

RAG answers with `--citation-required` could keep low-signal records with forced positive scores. Missing-context questions could therefore produce cited-looking answers instead of a clear refusal.

Affected behavior:

- Missing-context refusal
- Confusing-question refusal
- Citation-required answer gating

## 3. Root Cause

The ranker gave unmatched records a fallback score instead of preserving a zero score. The answerer then treated records with citations as sufficient even when no record had positive query relevance.

## 4. Fix Summary

Repair commit:

`eeb0aa8 fix(v1): close l1 backend deepwater blocker`

Changed files:

- `heitang_kb_forge/agent_rag/ranker.py`
- `heitang_kb_forge/agent_rag/answerer.py`
- `tests/test_agent_rag_ask.py`

Fix:

- Remove forced positive score fallback for unmatched records.
- Ignore common low-signal stopwords.
- Require positive context when citations are required.
- Add regression coverage for missing-context refusal.

## 5. Validation

Targeted validation:

`python -m pytest tests/test_agent_rag_ask.py`

Affected full Python gate:

`python -m pytest tests/test_contract_backward_compatibility.py tests/test_v121_hardening.py tests/test_agent_rag_ask.py tests/test_agent_runtime_ask.py tests/test_agent_rag_citation_trace.py tests/test_agent_rag_config_pipeline.py tests/test_runtime_connector_config.py tests/test_vector_export.py`

Result:

`19 passed`

Evidence:

- `reports/v1_l1_backend_deepwater_regression_logs/python_l1_affected_tests.stdout.log`
- `reports/v1_l1_backend_deepwater_regression_logs/python_l1_affected_tests_rerun.stdout.log`
- `reports/v1_l1_backend_deepwater_rag_logs/`
- `output/v1_l1_backend_deepwater/rag_assertions/`

## 6. Closure

RAG missing-context refusal is closed.

Residual risk:

P2 - citation/source trace granularity can be further improved in a later version, but the L1 blocker is closed.

Current state:

`continue_to_next_phase`
