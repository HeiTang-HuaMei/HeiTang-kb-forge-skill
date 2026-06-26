# Contributing

This repository is governed by the current product baseline:

- `docs/current/CURRENT_PRODUCT_BASELINE.md`
- `docs/product/PRODUCT_ARCHITECTURE.md`
- `docs/product/PRD.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX.md`

The versioned files dated `2026-06-19` remain the canonical source files. The unversioned files are stable pointers for GitHub review and CI policy.

## Change Rules

- Keep user-visible behavior unchanged unless the issue or PR explicitly requests a product change.
- Do not convert `reference_only`, readiness-only, or `needs_verification` external projects into integrated runtime claims without evidence.
- Do not call test-only or zero-token model routes release providers.
- Do not expose API keys, Redis passwords, vector DB tokens, or provider secrets in docs, UI, logs, or exports.
- Do not create stable tags or GitHub Releases from normal PR work.
- Do not submit build outputs, runtime output folders, generated logs, or local smoke artifacts.

## Required PR Evidence

Every PR should state:

- Product baseline impact.
- Runtime/UI/docs scope.
- Validation commands run.
- Secret and overclaim scan result.
- Whether Owner retest is required.

For Workbench changes, use the current code map:

- `docs/code_map/WORKBENCH_CODE_MAP_AFTER_CODE_CLEANUP.md`

## Fast Gate

Use the narrowest validation that proves the change. For normal repository changes:

```powershell
python -m pytest
git diff --check
```

For Flutter Workbench changes:

```powershell
cd web\workbench\flutter_app
flutter analyze
flutter test --concurrency=1
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1
```

If local Flutter tests are run behind a VPN or proxy, bypass loopback addresses first so the test shell can reach its own listener:

```powershell
$env:NO_PROXY='localhost,127.0.0.1,::1'
$env:no_proxy='localhost,127.0.0.1,::1'
```

Build or release gates are required only when the change affects packaging, release policy, or executable behavior.
