# V1 L1 Backend Deepwater RAG Citation Report

Generated: 2026-06-30

## 1. Scope

This report records Phase 4 RAG Refusal / Citation / Source Trace Test.

The V1.0 UI does not expose every low-level RAG assertion path, so this phase uses the Core/CLI reachable chain and records the evidence under `output/v1_l1_backend_deepwater/rag_assertions/`.

## 2. Evidence Paths

Logs:

`reports/v1_l1_backend_deepwater_rag_logs/`

Assertions:

`output/v1_l1_backend_deepwater/rag_assertions/`

RCA:

`reports/V1_L1_BACKEND_DEEPWATER_RAG_CITATION_RCA_REPORT.md`

## 3. Case Matrix

| Case | Exit code | Expected behavior | Result |
| --- | ---: | --- | --- |
| `retrieve_hit_en` | 0 | Retrieve relevant controlled fact with citation trace | pass |
| `ask_hit_en` | 0 | Answer hit question with citations | pass |
| `ask_hit_txt` | 0 | Answer TXT-backed controlled fact with citations | pass |
| `ask_missing_rerun` | 0 | Refuse missing context, citation count 0 | pass |
| `ask_confusing_missing_rerun` | 0 | Refuse confusing missing context, citation count 0 | pass |

## 4. Acceptance Checks

| Check | Result |
| --- | --- |
| Hit questions cite package evidence | pass |
| Missing questions do not fabricate | pass |
| Confusing missing questions do not fabricate | pass |
| Citation-required mode requires positive context | pass after repair |
| `citation_trace.json` exists for answer outputs | pass |
| `source_trace.json` and `evidence_map.json` remain available in package outputs | pass |
| `capability_chain_status.json` unchanged | pass |

## 5. Key Assertion Values

`output/v1_l1_backend_deepwater/rag_assertions/ask_missing_rerun/answer_report.json`:

- `insufficient_context`: `true`
- `citation_count`: `0`

`output/v1_l1_backend_deepwater/rag_assertions/ask_confusing_missing_rerun/answer_report.json`:

- `insufficient_context`: `true`
- `citation_count`: `0`

`output/v1_l1_backend_deepwater/rag_assertions/ask_hit_en/answer_report.json`:

- `insufficient_context`: `false`
- `citation_count`: `5`

## 6. Phase Result

Phase 4 result:

pass after repair

Allowed next phase:

Phase 5 - Document Generation Full Chain Test

Current state:

`continue_to_next_phase`
