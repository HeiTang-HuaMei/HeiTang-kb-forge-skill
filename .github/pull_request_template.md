## Scope

- Gate / task:
- Product baseline impact:
- Runtime/UI/docs scope:

## Baseline Checklist

- [ ] Aligned with `docs/current/CURRENT_PRODUCT_BASELINE.md`.
- [ ] Does not conflict with Product Architecture / PRD / Feature Acceptance Matrix.
- [ ] Does not convert reference-only or readiness-only external projects into integrated runtime claims.
- [ ] Does not describe test-only or zero-token routes as release providers.

## Validation

- [ ] `python -m pytest`
- [ ] `git diff --check`
- [ ] Flutter validation, if Workbench code changed.
- [ ] no-secret scan
- [ ] overclaim scan
- [ ] OKF boundary scan, if product docs/runtime changed.

## Owner Retest

- [ ] Not required.
- [ ] Required and checklist attached.

## Release Boundary

- [ ] No stable tag.
- [ ] No GitHub Release.
- [ ] No build outputs, logs, local runtime output, or secrets committed.
