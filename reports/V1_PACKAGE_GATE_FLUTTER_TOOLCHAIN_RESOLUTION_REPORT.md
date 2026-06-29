# V1 Package Gate Flutter Toolchain Resolution Report

Generated: 2026-06-30

## 1. Scope

Current input state:

`package_gate_flutter_ui_retry_failed_pending_failure_review`

This report records the Owner-authorized Package Gate Flutter toolchain resolution fix. The goal is limited to resolving Flutter executable discovery for the Tauri Package Gate script.

Not performed:

- Package Gate retry
- build/package
- push
- tag/release
- Final Owner Review
- `capability_chain_status.json` modification
- Flutter product code modification
- UI redesign
- architecture extraction

## 2. Retry Failure Summary

Failed retry report:

`reports/V1_PACKAGE_GATE_FLUTTER_UI_RETRY_RESULT_REPORT.md`

Failed retry command:

`.\packaging\desktop\build_tauri.ps1`

Failed retry exit code:

`1`

Direct failure:

`flutter.cmd` was not found before Flutter web build could run.

Impact:

- no new valid Package Gate artifact was produced
- existing NSIS artifact remains a prior artifact and is not accepted as this retry output
- provenance verification stayed failed / blocked
- Tauri build was not reached

## 3. Environment Check

Flutter command discovery:

| Check | Result |
| --- | --- |
| `where.exe flutter` | `C:\src\flutter\bin\flutter`; `C:\src\flutter\bin\flutter.bat` |
| `where.exe flutter.bat` | `C:\src\flutter\bin\flutter.bat` |
| `where.exe flutter.cmd` | not found |
| `Get-Command flutter` | `C:\src\flutter\bin\flutter.bat` |
| `Get-Command flutter.bat` | `C:\src\flutter\bin\flutter.bat` |
| `Get-Command flutter.cmd` | not found |

Flutter environment variables:

| Variable | Value |
| --- | --- |
| `FLUTTER_BIN` | unset |
| `FLUTTER_ROOT` | unset |
| `FLUTTER_HOME` | unset |

Environment conclusion:

Flutter is installed and reachable through `flutter` / `flutter.bat`, but not through `flutter.cmd`. The previous script hard dependency on `flutter.cmd` caused the retry failure in this Windows environment.

## 4. Script Root Cause

File:

`packaging/desktop/build_tauri.ps1`

Previous Flutter invocation:

`flutter.cmd build web`

Root cause:

The script hard-coded `flutter.cmd` and had no executable fallback, environment override, or clear missing-toolchain error message.

## 5. `build_tauri.ps1` Modification Summary

The script now resolves the Flutter executable before running Flutter web build.

New behavior:

- defines `Resolve-FlutterExecutable`
- checks explicit environment configuration first
- falls back to PATH commands
- records the actual Flutter executable path with `Write-Host`
- invokes Flutter through the resolved executable path
- preserves native command exit-code handling
- preserves the required `flutter build web` step
- preserves the Tauri build and NSIS artifact checks
- does not swallow real Flutter build failures
- does not bypass package errors

PowerShell syntax check:

passed using `[System.Management.Automation.PSParser]::Tokenize(...)`

Package Gate retry:

not run

## 6. New Flutter Command Resolution Order

Resolution order:

1. `FLUTTER_BIN`
2. `FLUTTER_ROOT\bin\flutter.bat`
3. `FLUTTER_HOME\bin\flutter.bat`
4. PATH command `flutter`
5. PATH command `flutter.bat`
6. PATH command `flutter.cmd`

`FLUTTER_BIN` may point either to a Flutter executable file or to a Flutter `bin` directory containing `flutter.bat`.

## 7. Missing Flutter Error

If no Flutter executable can be resolved, the script now emits:

`Flutter executable not found. Set FLUTTER_BIN or add Flutter bin to PATH.`

The script exits with code `1` in that case.

## 8. Why This Is Packaging/Toolchain Only

This change only affects how the Package Gate script locates the Flutter executable.

It does not modify:

- Flutter product source under `web/workbench/flutter_app/lib`
- Tauri UI source semantics
- application behavior
- `capability_chain_status.json`
- Package Gate success criteria

The script still must run `flutter build web`, verify `build/web/index.html`, run `tauri build`, and verify an NSIS setup artifact.

## 9. Safety Checks

`capability_chain_status.json` diff:

empty

Ready-claim scan:

clean / non-claim only

Classification:

- product code, tests, and `capability_chain_status.json` contain no new actual positive Package Gate or release-readiness claim
- existing matches are domain fields, tests, fixtures, forbidden-term lists, negative statements, or authorization-gated evidence text
- this report does not claim Package Gate pass or release readiness

## 10. Next Step

Next required Owner action:

Authorize a clean Package Gate Flutter UI retry.

The retry should verify:

- resolved Flutter executable path is logged
- `flutter build web` runs successfully
- `web/workbench/flutter_app/build/web/index.html` exists
- Tauri packages `web/workbench/flutter_app/build/web`
- a new NSIS artifact is produced
- no tracked drift appears
- `capability_chain_status.json` diff remains empty
- ready-claim scan remains clean / non-claim only
- packaged UI matches the current Flutter V1 UI

Completion state after commit:

`v1_package_gate_flutter_toolchain_fix_committed_pending_retry_authorization`
