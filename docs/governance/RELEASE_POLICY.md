# Release Policy

Release is allowed only when product baseline, runtime evidence, CI, security, and Owner retest agree.

## Required Gates

1. PR fast gate.
2. Nightly full gate, when available.
3. RC candidate gate.
4. Release gate.
5. Owner retest.

## Baseline Gate

Release notes and public docs must align to:

- `docs/current/CURRENT_PRODUCT_BASELINE.md`
- `docs/product/PRODUCT_ARCHITECTURE.md`
- `docs/product/PRD.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX.md`

## Runtime Claim Gate

Release notes must not claim:

- all external runtimes are integrated,
- unverified Provider candidates are user-selectable,
- test-only zero-token routes are release providers,
- reference-only projects are product modules,
- OKF is a first-level runtime module unless a future baseline explicitly says so.

## Artifact Gate

Do not include local output folders, EXE smoke logs, build outputs, or raw runtime logs in release commits.
