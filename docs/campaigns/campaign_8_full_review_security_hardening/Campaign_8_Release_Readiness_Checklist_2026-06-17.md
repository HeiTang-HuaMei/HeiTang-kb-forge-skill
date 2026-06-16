# Campaign 8 Release Readiness Checklist

Date: 2026-06-17

Status: campaign8_release_readiness_accepted_pushed_ci_green_tagged_rc1

| Checklist Item | Status |
| --- | --- |
| Campaign 7 accepted and CI green | pass |
| Core full/high-risk suites | pass |
| UI analyze/test/build | pass |
| clean clone verification | pass |
| no-secret full scan | pass |
| overclaim scan | pass |
| security regression | pass |
| UI/Core contract consistency | pass after contract asset sync |
| Campaign 9 not started | pass |
| Computer Use runtime disabled | pass |
| GitHub Release not created | pass |
| Core remote CI | pass, run `27644362304` |
| UI remote CI | pass, run `27645182917` |

## RC Policy

After this final Campaign 8 evidence anchor receives Core remote CI green, tag `v4.3.0-rc1` is created and pushed. GitHub Release must not be created.
