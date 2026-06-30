# V1 L1 Backend Deepwater Regression RCA Report

Generated: 2026-06-30

## 1. Scope

This report records Phase 10 regression RCA.

It covers the proxy-related local Flutter test rerun issue and the RC6 project-config asset path failure discovered during full regression.

## 2. Failure Summary

Failure class:

regression failure

Observed issues:

1. Flutter widget/RC6 reruns initially failed under proxy behavior. Rerun with `NO_PROXY=127.0.0.1,localhost,::1` resolved the local test-server path.
2. Full RC6 later exposed `PathNotFoundException` for `project_config_assets.json` under a workbook config directory.
3. The project config industrial isolation test exceeded the default timeout window.

Evidence:

- `reports/v1_l1_backend_deepwater_regression_logs/flutter_rc6_test_no_proxy_long.stdout.log`
- `reports/v1_l1_backend_deepwater_regression_logs/flutter_rc6_project_config_isolation_targeted.stdout.log`
- `reports/v1_l1_backend_deepwater_regression_logs/flutter_rc6_project_config_isolation_precise_rerun.stdout.log`

## 3. Root Cause

The RC6 project-config writer assumed the destination parent directory existed before writing `project_config_assets.json`.

The test also required a longer timeout budget than the default test timeout.

## 4. Fix Summary

Repair commit:

`eeb0aa8 fix(v1): close l1 backend deepwater blocker`

Changed files:

- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`
- `web/workbench/flutter_app/test/rc6_runtime_truth_blocker_repair_test.dart`

Fix:

- Ensure the parent directory exists before writing project config assets.
- Apply the existing slow runtime timeout to the project config isolation test.

## 5. Validation

Targeted validation:

- `flutter_rc6_project_config_isolation_precise_rerun`: exit code `0`
- `flutter_rc6_connector_industrialization_targeted`: exit code `0`

Full affected gate:

- `flutter_rc6_test_no_proxy_full_after_fix`: exit code `0`
- Result: `136 passed / 1 skipped`

Additional validations:

- Python affected tests: `19 passed`
- Flutter analyze: pass
- Widget test with `NO_PROXY`: `28 passed`

## 6. Closure

Regression failure is closed.

Residual risk:

P2 - long-running local Flutter tests should continue using local-loopback proxy bypass to avoid environment proxy interference.

Current state:

`continue_to_next_phase`
