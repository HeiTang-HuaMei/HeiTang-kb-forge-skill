# Validation Strategy

This policy is part of v4.1.0 Test Governance Emergency Hardening. It defines impact-based staged validation for development work, phase closure, and final tag/release gates.

## Before Any Validation Phase

Every validation phase must start here:

1. Read this strategy.
2. Generate a changed-file impact map.
3. Select Fast / Medium / Full Gate.
4. Run only impacted tests during development.
5. Run Medium Gate at phase closure.
6. Run Chunked Full Gate before tag/release.
7. Preserve logs and exit codes for long-running gates.
8. Report skipped/deferred checks with reason.
9. Never report skipped/deferred checks as passed.

## Gate Levels

### Fast Gate

Use Fast Gate during development when the changed-file impact is narrow and the work is still in progress.

Fast Gate must include:

- impacted unit or contract tests for the files changed
- relevant CLI smoke tests when command behavior changes
- `git diff --check`
- a note listing any deferred tests and why they are deferred

Fast Gate is not enough for phase closure, tag, or release.

### Medium Gate

Use Medium Gate before closing a phase, checkpoint, or release-hardening slice.

Medium Gate must include:

- all Fast Gate checks
- focused tests for the touched capability area
- docs/truth tests when README, capability matrix, current truth, changelog, roadmap, or audit docs change
- parser backend focused tests when parser/OCR files, contracts, fixtures, or evidence change
- release-readiness or doctor checks when release metadata or setup instructions change

Medium Gate is enough to hand off a phase for review, but it is not enough to tag or publish a release.

### Full Gate

Full Gate is mandatory before tag or release.

Full Gate must include:

- full Core `python -m pytest`
- focused parser backend tests for P2.1 parser/OCR work
- release-readiness, doctor, and quickstart checks when preparing a release
- `git diff --check`
- hygiene scans for secrets, build outputs, raw runtime outputs, local provider config, and large generated artifacts
- UI validation when Workbench fixtures, contracts, assets, or visible surfaces change
- CI green for the release commit and tag/release workflow when a tag is created

Do not create or push a release tag until Full Gate passes.

### Chunked Full Gate

Long-running Full Gate checks must be auditable. Do not use one opaque 40-minute `python -m pytest` command as the only release evidence.

Chunked Full Gate requires:

- each chunk runs as a separate command
- each chunk preserves a log under `docs/audits/test_engineering/full_gate_logs/`
- each chunk records an exit code
- all chunks pass before Full Gate is reported as passed
- if a tool timeout loses output or exit code, that chunk is not passed
- if the full suite remains too slow for one reliable chunk, split by test area until each chunk has a preserved log and exit code

Recommended Core chunks:

```powershell
python -m pytest tests/test_final_docs_truthfulness.py tests/test_final_bilingual_docs_parity.py tests/test_final_docs_structure.py tests/test_release_checklist_docs.py tests/test_readme_scope.py tests/test_version_alignment.py tests/test_version_matrix_docs.py -q
python -m pytest tests/test_v28_parser_backends.py tests/test_external_project_registry.py tests/test_planned_adapter_boundaries.py tests/test_s_a_contract_inclusion.py tests/test_post_v4_external_roadmap.py -q
python -m pytest -q
```

Recommended UI chunks:

```powershell
python -m pytest
flutter analyze
flutter test -r expanded
flutter build web
flutter build windows
```

For final tag/release, preserve each command's log and exit code in the validation report.

## Changed-File Impact Map

| Changed files | Required validation |
| --- | --- |
| `heitang_kb_forge/parser_backends/**`, parser CLI commands, parser contracts | Parser backend focused tests, CLI smoke, evidence generation, docs/truth checks, Full Gate before release |
| `heitang_kb_forge/cli*.py`, command modules, command docs | Command focused tests, CLI smoke, command reference checks, `git diff --check` |
| `docs/**`, `README*`, `CHANGELOG.md`, `CURRENT_TRUTH.md`, `CAPABILITY_MATRIX.md` | Docs truth tests, link checks, bilingual parity where applicable |
| `docs/audits/**`, evidence JSON/Markdown reports | Evidence schema/consistency tests, audit index link checks, no raw-output scan |
| `pyproject.toml`, `skill.json`, version metadata | Version alignment tests, doctor, release-readiness |
| Workbench contract/fixture/asset files | UI fixture drift tests, Flutter asset match tests, Flutter analyze/test/build when visible UI changes |
| `.github/workflows/**`, release scripts | CI workflow validation, release-readiness, Full Gate before tag/release |
| Secret, provider, network, local config handling | Security/privacy focused tests, secret scan, provider config scan |

When a change spans multiple rows, run the union of required validation.

## Current Fast Gate Commands

For Core docs/truth changes:

```powershell
python -m pytest tests/test_final_docs_truthfulness.py tests/test_final_bilingual_docs_parity.py tests/test_final_docs_structure.py tests/test_release_checklist_docs.py tests/test_readme_scope.py tests/test_version_alignment.py tests/test_version_matrix_docs.py -q
git diff --check
```

For Core parser/evidence changes:

```powershell
python -m pytest tests/test_v28_parser_backends.py tests/test_external_project_registry.py tests/test_planned_adapter_boundaries.py tests/test_s_a_contract_inclusion.py tests/test_post_v4_external_roadmap.py -q
git diff --check
```

For UI fixture/contract changes, run the impacted UI Python contract tests. For Flutter UI changes, run:

```powershell
flutter analyze
flutter test -r expanded
```

Fast Gate does not run Core full pytest, `flutter build web`, or `flutter build windows`.

## Skipped Or Deferred Test Reason Format

Every skipped or deferred check must be reported with:

```text
check:
gate_level:
reason:
impact:
risk:
replacement_evidence:
owner:
must_run_before:
```

Example:

```text
check: full Core python -m pytest
gate_level: Full Gate
reason: still running in CI; local focused suite passed
impact: release tag is blocked until full result is green
risk: undiscovered cross-module regression
replacement_evidence: parser backend focused tests and docs truth tests passed locally
owner: release operator
must_run_before: v4.1.0 tag/release
```

Skipped, timed-out, deferred, blocked, or unavailable checks must never be reported as passed. A report may say `not run`, `deferred`, `blocked`, or `failed`, but not `passed`.

Allowed skipped/deferred reasons:

- `not impacted by current changed files`
- `inherited from last green full gate`
- `deferred to medium gate`
- `deferred to final full gate`
- `blocked by environment with explicit reason`

Forbidden skipped/deferred reasons:

- `passed by default`
- `assumed passed`
- `probably unrelated`
- `skip because slow`

## Validation Report

Validation reports live under `docs/audits/test_engineering/` and must include:

- `selected_gate`
- `changed_files`
- `impacted_surfaces`
- `commands_run`
- `commands_deferred`
- `commands_skipped`
- `skip_reason`
- `exit_codes`
- `log_paths`
- `release_blocking`

## Release Rule

Full Gate is mandatory before any tag or release. For v4.1.0, do not tag or publish until Core and UI Chunked Full Gates pass, CI is green, hygiene scans are clean, and the stable `v4.0.0` tag remains untouched.
