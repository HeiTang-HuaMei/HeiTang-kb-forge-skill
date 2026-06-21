# rc12 GitHub Repository Governance Restructure Report

Gate: `rc12_github_repository_governance_restructure_gate`

Generated: 2026-06-21

Inputs:

- `docs/audits/current/rc11_product_code_systematic_cleanup_execution_report.md`
- `docs/code_map/WORKBENCH_CODE_MAP_AFTER_CODE_CLEANUP.md`

## Summary

This gate upgrades the repository governance surface without changing business runtime, UI behavior, product artifact paths, tags, or GitHub Releases.

It establishes GitHub-facing control points for:

- current product baseline,
- contribution and security policy,
- branch, tag, and release policy,
- external project registry policy,
- model gateway and Provider policy,
- Owner retest policy,
- issue and PR templates,
- CODEOWNERS,
- dependabot,
- layered CI workflow entry points.

## Current Product Baseline

Stable pointers were added:

- `docs/current/CURRENT_PRODUCT_BASELINE.md`
- `docs/product/PRODUCT_ARCHITECTURE.md`
- `docs/product/PRD.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX.md`

The dated v3 files remain canonical:

- `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
- `docs/product/PRD_V3_2026-06-19.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`

## Governance Files

Added:

- `CONTRIBUTING.md`
- `SECURITY.md`
- `ROADMAP.md`
- `docs/governance/BRANCH_POLICY.md`
- `docs/governance/TAG_POLICY.md`
- `docs/governance/RELEASE_POLICY.md`
- `docs/governance/EXTERNAL_PROJECT_REGISTRY.md`
- `docs/governance/MODEL_GATEWAY_PROVIDER_POLICY.md`
- `docs/governance/OWNER_RETEST_POLICY.md`

Existing Chinese governance files remain in place and are not rewritten.

## GitHub Control Surface

Added:

- `.github/pull_request_template.md`
- `.github/CODEOWNERS`
- `.github/dependabot.yml`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/capability_gap.yml`
- `.github/ISSUE_TEMPLATE/owner_retest_failure.yml`
- `.github/ISSUE_TEMPLATE/external_project_verification.yml`
- `.github/ISSUE_TEMPLATE/release_blocker.yml`

## Workflow Layers

Existing workflows retained:

- `.github/workflows/ci.yml`
- `.github/workflows/release-check.yml`

Added explicit governance workflow entry points:

- `.github/workflows/pr-fast-gate.yml`
- `.github/workflows/nightly-full-gate.yml`
- `.github/workflows/rc-candidate-gate.yml`
- `.github/workflows/release-gate.yml`
- `.github/workflows/docs-check.yml`
- `.github/workflows/security-scan.yml`

## External Project Boundary

This gate does not claim all external runtimes are integrated.

Current Stage3 wording remains:

- Provider / Gateway / ModelRoute / Profile / readiness / binding / rollback / audit mechanisms are established.
- External projects remain governed as Provider candidates, template assets, absorbed architecture references, rejected references, or deferred references with explicit blockers.
- `reference_only`, readiness-only, and test-only routes are not release providers.

## Release Boundary

This gate did not:

- create a stable tag,
- create a GitHub Release,
- rewrite Git history,
- delete historical tags,
- submit build outputs,
- submit runtime output folders,
- change runtime behavior.

## Validation

Local validation before commit:

- `python -m pytest`: passed, 507 passed / 1 skipped.
- Workflow and issue-template YAML parse: passed.
- `python -m pytest tests/test_ci_workflows_exist.py -q`: passed.
- `git diff --check`: passed with line-ending warnings only.
- High-confidence no-secret scan over the governance diff: passed.
- Overclaim scan over the governance diff: passed; no new claim says all external runtimes are integrated, no unverified runtime is promoted, and no test-only route is described as a release Provider.
- OKF boundary scan over the governance diff: passed; no new first-level OKF runtime/page/provider claim was introduced.
- `python -m pytest -m docs_truth -q`: no marked tests were selected in this repository state, so it was treated as not applicable rather than a passing evidence gate.

Remote CI is pending until this gate is committed and pushed.

## Remaining Risk

Some legacy docs still carry historical version and rc language. They are retained for traceability and remain subordinate to `docs/current/CURRENT_PRODUCT_BASELINE.md` and the dated v3 product baseline.
