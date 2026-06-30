# V1 L1 Backend Deepwater Import Build Report

Generated: 2026-06-30

## 1. Scope

This report records Phase 2 Core Import / Build Chain Deep Test.

It uses the reproducible dataset under:

`output/v1_l1_backend_deepwater/test_dataset/`

## 2. Commands

Representative command shape:

`python -m heitang_kb_forge.cli build --input <input> --output <output> --rag-export --retrieval-index --evidence-gate --run-manifest --progress-jsonl --contract-version v2`

Logs:

`reports/v1_l1_backend_deepwater_import_build_logs/`

Artifacts:

`output/v1_l1_backend_deepwater/import_build_artifacts/`

## 3. Case Matrix

| Case | Exit code after fix | Source trace | Evidence map | Error report | Result |
| --- | ---: | --- | --- | --- | --- |
| `single_cn` | 0 | present | present | present, 0 errors | pass |
| `success_mixed` | 0 | present | present | present, 0 errors | pass |
| `with_failure_files` | 0 | present | present | present, 1 corrupt PDF error | pass |
| `duplicates_near_duplicates` | 0 | present | present | present, 0 errors | pass |
| `reimport_success_mixed` | 0 | present | present | present, 0 errors | pass |

Summary file:

`reports/v1_l1_backend_deepwater_import_build_logs/phase2_build_summary.rerun.json`

## 4. Acceptance Checks

| Check | Result |
| --- | --- |
| Successful files produce traceable package outputs | pass |
| Corrupt PDF failure is recorded without poisoning successful files | pass |
| Empty source is recorded as warning and does not poison successful files | pass |
| Duplicate basename sources keep source paths | pass |
| Near-duplicate files remain explainable | pass |
| Reimport/rebuild produces a fresh valid package | pass |
| `source_trace.json` exists for contract v2 outputs | pass |
| `evidence_map.json` exists for contract v2 outputs | pass |
| `capability_chain_status.json` unchanged | pass |

## 5. Repair Closure

Initial P1:

corrupt PDF stopped the full build and exposed an internal traceback.

Repair evidence:

`reports/V1_L1_BACKEND_DEEPWATER_IMPORT_BUILD_RCA_REPORT.md`

Targeted validation:

`python -m pytest tests/test_contract_backward_compatibility.py tests/test_v121_hardening.py`

Result:

`6 passed`

## 6. Residual Risk

P2:

Chinese title display in one source trace console sample appeared as question marks. The source path, citation, and chunk identifiers remained present.

## 7. Phase Result

Phase 2 result:

pass after repair

Allowed next phase:

Phase 3 - Interruption / Kill / Recovery Test

## 8. Current State

`continue_to_next_phase`
