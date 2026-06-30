# V1 L1 Backend Deepwater Import Build RCA Report

Generated: 2026-06-30

## 1. Scope

This RCA records the Phase 2 import/build P1 failure and the minimal backend repair.

No UI redesign, packaging change, architecture extraction, or `capability_chain_status.json` change was performed.

## 2. Failure Summary

Initial Phase 2 case:

`with_failure_files`

Initial result:

exit code `1`

Observed failure:

- a corrupt PDF raised a parser exception
- the whole build stopped
- no package outputs were produced for the remaining valid files in that case
- the CLI exposed an internal traceback in the log

Risk classification:

P1

Reason:

A single bad source file could block an otherwise valid backend import/build batch, and the failure path was not friendly enough for V1.0 backend deepwater acceptance.

## 3. Root Cause

`_build_package` re-raised generic source parsing exceptions after emitting progress failure.

That behavior is acceptable for narrow parser-level tests, but not for V1.0 deepwater import/build acceptance where corrupt or empty inputs must be isolated from valid sources.

## 4. Minimal Fix

Changed:

- `heitang_kb_forge/cli_runtime.py`

Fix summary:

- source parsing exceptions are recorded as warnings
- run-manifest `error_report.json` now records parse errors
- build continues to parse remaining sources
- contract v2 output now writes `source_trace.json`
- contract v2 manifest now lists `source_trace.json`

Tests added/updated:

- `tests/test_v121_hardening.py`
- `tests/test_contract_backward_compatibility.py`

## 5. Validation

Targeted validation:

`python -m pytest tests/test_contract_backward_compatibility.py tests/test_v121_hardening.py`

Result:

`6 passed`

Phase 2 rerun:

`reports/v1_l1_backend_deepwater_import_build_logs/phase2_build_summary.rerun.json`

Rerun result:

- `single_cn`: exit code `0`
- `success_mixed`: exit code `0`
- `with_failure_files`: exit code `0`, one corrupt PDF error recorded
- `duplicates_near_duplicates`: exit code `0`
- `reimport_success_mixed`: exit code `0`

## 6. Residual Risk

P2:

Chinese title display in one generated source trace sample appeared as question marks in console rendering. The citation/source path/chunk links remained present. This is tracked as display polish unless later evidence shows source trace corruption.

## 7. Current State

`continue_to_next_phase`
