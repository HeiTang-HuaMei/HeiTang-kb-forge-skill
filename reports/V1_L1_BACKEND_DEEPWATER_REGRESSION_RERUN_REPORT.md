# V1 L1 Backend Deepwater Regression Rerun Report

Generated: 2026-06-30

## 1. Scope

This report records Phase 10 Regression Re-Run.

## 2. Evidence Paths

Logs:

`reports/v1_l1_backend_deepwater_regression_logs/`

RCA:

`reports/V1_L1_BACKEND_DEEPWATER_REGRESSION_RCA_REPORT.md`

Repair commit:

`eeb0aa8 fix(v1): close l1 backend deepwater blocker`

## 3. Regression Matrix

| Gate | Result | Evidence |
| --- | --- | --- |
| Python L1 affected tests | 19 passed | `python_l1_affected_tests.stdout.log` |
| Python L1 affected tests rerun | 19 passed | `python_l1_affected_tests_rerun.stdout.log` |
| Flutter analyze | pass | `flutter_analyze_rerun.stdout.log` |
| Flutter widget test with `NO_PROXY` | 28 passed | `flutter_widget_test_no_proxy.stdout.log` |
| RC6 targeted project config precise rerun | pass | `flutter_rc6_project_config_isolation_precise_rerun.stdout.log` |
| RC6 targeted connector rerun | pass | `flutter_rc6_connector_industrialization_targeted.stdout.log` |
| Full RC6 after fix with `NO_PROXY` | 136 passed / 1 skipped | `flutter_rc6_test_no_proxy_full_after_fix.stdout.log` |
| `npm run typecheck` | not applicable | no root package.json and no desktop typecheck script |

## 4. Acceptance Checks

| Check | Result |
| --- | --- |
| Affected Python tests pass | pass |
| Flutter analyze pass | pass |
| Widget test pass | pass |
| RC6 full affected gate pass | pass |
| Regression failure has RCA | pass |
| Regression failure has repair commit | pass |
| Regression failure has targeted and full validation | pass |
| `capability_chain_status.json` unchanged | pass |

## 5. Phase Result

Phase 10 result:

pass after repair

Allowed next phase:

Phase 11 - Evidence Consistency and Risk Matrix

Current state:

`continue_to_next_phase`
