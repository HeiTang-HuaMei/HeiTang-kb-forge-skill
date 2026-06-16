# Campaign 8 Full Review / Regression Report

Date: 2026-06-17

Status: campaign8_full_review_security_hardening_accepted_pushed_ci_green_tagged_rc1

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
| Core remote CI | `05b72ad`, run `27644362304`, success |
| UI remote CI | `6b935d6`, run `27645182917`, success |

## Regression Fixes

Campaign 8 found a UI/Core contract drift in `external_capability_registry.json` and `s_a_contract_inclusion_matrix.json`. The UI assets were synchronized from the accepted Core external capability generator, and the UI contract test was updated to assert durable boundary semantics rather than stale hardcoded counts.

## Boundaries

Campaign 8 did not enter EXE packaging. Campaign 9 is not started by this report. The `v4.3.0-rc1` tag is created only after this final evidence anchor receives Core remote CI green; no GitHub Release is created.
