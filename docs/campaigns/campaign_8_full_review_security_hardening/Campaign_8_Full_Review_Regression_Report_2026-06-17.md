# Campaign 8 Full Review / Regression Report

Date: 2026-06-17

Status: campaign8_local_regression_pass_pending_commit_push_ci

## Scope

Campaign 8 performed full product regression and consistency hardening only. No large feature implementation, EXE packaging, Computer Use runtime, arbitrary shell, GitHub Release, or Campaign 9 work was started.

## Regression Results

| Gate | Result |
| --- | --- |
| Core full pytest | `1421 passed, 1 skipped` |
| Core failed subset after fix | `23 passed` |
| Core security regression subset | `24 passed` |
| UI Flutter analyze | No issues found |
| UI Flutter test | `79 passed` with local no-proxy env |
| UI Flutter build web | built `build\web` |
| Clean clone focused verification | install pass; `9 passed` |
| Core/UI `git diff --check` | pass with CRLF warnings only |

## Regression Fixes

Campaign 8 found a UI/Core contract drift in `external_capability_registry.json` and `s_a_contract_inclusion_matrix.json`. The UI assets were synchronized from the accepted Core external capability generator, and the UI contract test was updated to assert durable boundary semantics rather than stale hardcoded counts.

## Boundaries

Campaign 8 did not enter EXE packaging. Campaign 9 is not started by this report.
