# P1 Integrated Local Workbench Acceptance Gate

Generated: 2026-06-09T13:50:10+08:00

## Verdict

`p1_integrated_gate_status=blocked`.

The Core x UI acceptance checks passed for contract generation, fixture drift, route/action coverage, desktop/web bridge safety, theme/i18n regression, and local validations. The gate remains blocked because the Core P1 gate honestly declares `ui_full_operation_pending=true`, `p1_full_operation_gate_status=blocked`, and `not_v4_0_workbench_rc=true`. This is not a v4.0 release, no tag was created, and no v4 release was written.

## Repositories

| Repo | Branch | Baseline commit | Validation commit | CI |
| --- | --- | --- | --- | --- |
| Core | `main` | `1e786cd1da1f557cd22eae622a721c431902e6b4` | `42badea23ad006a7ec4bc0f0a4094cf4ec8a6fc7` | `27181345445` success; baseline `27179494913` success |
| UI | `feature/workbench-ui-prototype` | `a18bfa451088577f25cdc7c685f8871bb3442dff` | `c47215332c261f63a9f60663ea3b72a4b2f38549` | `27186563505` success; baseline `27184428350` success |

Core validation commit is one documentation-only commit after the P1 contract baseline. The generated Core P1 contract pack still matches the UI fixture IDs, counts, task statuses, templates, and gate fields.

## Core Contract Check

Command:

```powershell
python -m heitang_kb_forge.cli_runtime workbench-contracts --profile p1 --output ..\_tmp_p1_core_contracts
```

Result: passed. Required files were generated, including `workbench_manifest.json`, action contracts, capability matrix, report/artifact registries, error taxonomy, schemas, template registry, and `workbench_p1_gate_report.json`.

Counts: 16 pages, 110 actions, 109 reports, 101 artifacts, 20 error codes, 6 templates. Gate fields: `core_contract_ready=true`, `ui_full_operation_pending=true`, `p1_full_operation_gate_status=blocked`, `not_v4_0_workbench_rc=true`.

## UI Drift And Coverage

Drift status: clean after a small UI acceptance fix. The UI fixture matches Core-generated action IDs, report IDs, artifact IDs, error codes, capability page mapping, task statuses, templates, and gate fields.

Small UI fix: commit `c47215332c261f63a9f60663ea3b72a4b2f38549` declared `p1_core_contracts` for every page in `web/workbench/contracts.json`, tightened the Python contract test, and expanded Flutter widget render coverage for Task / Job Center and Reports & Audit.

Route/action/report/artifact/error/task coverage: passed fixture-backed checks. This is not claimed as real full-operation workflow execution.

## Desktop/Web Boundary

Desktop bridge smoke passed through Flutter tests: allowlist, `runInShell:false`, shell metacharacter rejection, secret environment rejection, stdout/stderr/command preview redaction, non-zero exit handling, timeout handling, and fake runner action lifecycle. Web runtime remains unsupported for local CLI and does not call the runner.

Theme/i18n regression passed: Windows desktop shell, black/white/gray premium palette, light/dark toggle, zh-CN/en-US switch, no NavigationRail desktop main nav, no macOS shell controls.

## Validations

Core:

- `python -m pytest tests -k "p1 or workbench"`: 30 passed, 806 deselected.
- `python -m pytest`: 835 passed, 1 skipped.
- `git diff --check`: passed.
- Safety grep: broad pattern reviewed with expected documentation/test hits; high-entropy secret-like scan found no hits.

UI:

- `python -m pytest`: 474 passed, 1 skipped.
- Workbench Python tests: 34 passed.
- `flutter pub get`: passed.
- `flutter analyze`: no issues.
- `flutter test -r expanded`: 15 tests passed.
- `flutter build web`: passed.
- `flutter build windows`: passed; build output not committed.
- Safety grep: expected hits only; no `runInShell: true` product path.

## Blockers

- Core gate reports `ui_full_operation_pending=true` and `p1_full_operation_gate_status=blocked`.
- UI page workflows are fixture-backed; desktop bridge smoke uses fake/injected runner and is not a real large local user workflow.
- Planned/provider/secret/mock-only actions remain blocked and were not marked ready.

## Recommendation

Keep P1 Integrated Gate blocked until full-operation UI workflows are wired to real safe Core execution paths and planned adapters are no longer blocked. Do not start v4.0 and do not mark this as a v4 release or v4 RC candidate.
