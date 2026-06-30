# V1 L1 Knowledge Base Supplement Report

Generated: 2026-06-30

## 1. Scope

This report confirms that Knowledge Base evidence is based on real generated chunks/cards/qa pairs, evidence maps, source trace, rebuild evidence, and RAG citation evidence.

## 2. Test Input

Dataset:

`output/v1_l1_backend_deepwater/workspaces/phase2_success_input/`

Rebuild dataset:

`output/v1_l1_backend_deepwater/workspaces/phase2_success_input/`

## 3. Execution Path

Core build / rebuild path:

`python -m heitang_kb_forge.cli build ... --rag-export --retrieval-index --evidence-gate --contract-version v2`

RAG assertion path:

`python -m heitang_kb_forge.cli retrieve ...`

`python -m heitang_kb_forge.cli ask ...`

## 4. Evidence Paths

Knowledge artifacts:

- `output/v1_l1_backend_deepwater/import_build_artifacts/success_mixed/`
- `output/v1_l1_backend_deepwater/import_build_artifacts/success_mixed_reimport/`
- `output/v1_l1_backend_deepwater/import_build_artifacts/with_failure_files/`

RAG assertions:

- `output/v1_l1_backend_deepwater/rag_assertions/ask_hit_en/`
- `output/v1_l1_backend_deepwater/rag_assertions/ask_hit_txt/`
- `output/v1_l1_backend_deepwater/rag_assertions/ask_missing_rerun/`
- `output/v1_l1_backend_deepwater/rag_assertions/ask_confusing_missing_rerun/`

Reports:

- `reports/V1_L1_BACKEND_DEEPWATER_IMPORT_BUILD_REPORT.md`
- `reports/V1_L1_BACKEND_DEEPWATER_RAG_CITATION_REPORT.md`

## 5. Observed Values

| Check | Result |
| --- | --- |
| Real KB build output | pass |
| `chunks.jsonl` | pass, `5` lines in `with_failure_files` |
| `cards.jsonl` | pass, `5` lines in `with_failure_files` |
| `qa_pairs.jsonl` | pass, `5` lines in `with_failure_files` |
| `evidence_map.json` | present |
| `source_trace.json` | present and points to md/txt/docx/pdf source files |
| Delete/rebuild equivalent | pass, `success_mixed_reimport` generated fresh package with `0` errors |
| RAG real citation | pass, `ask_hit_en` has `citation_count = 5` |
| Missing RAG refusal | pass, missing questions have `insufficient_context = true` and `citation_count = 0` |
| Orphan record symptom | not observed in rebuild evidence |

## 6. Result

Status:

pass

Risk:

P0 = 0, P1 = 0, P2 = 0, P3 = 0

Fix required:

No.

## 7. Safety Checks

`capability_chain_status.json` diff:

empty

ready-claim scan:

clean / non-claim only after classification
