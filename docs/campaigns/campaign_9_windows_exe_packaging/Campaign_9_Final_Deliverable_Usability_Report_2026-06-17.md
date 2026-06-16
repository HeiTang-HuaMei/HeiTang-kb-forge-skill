# Campaign 9 Final Deliverable Usability Report

Date: 2026-06-17

Status: local desktop delivery usable, pending remote CI

## Usability Checklist

| Requirement | Result | Evidence |
| --- | --- | --- |
| Package starts | pass | desktop shell smoke launch step |
| Core UI opens | pass | Windows runner smoke reached a window handle |
| Minimize/maximize/restore/resize/close work | pass | desktop shell smoke JSON |
| Campaign 4/5/6 entries remain accessible | pass | existing Workbench navigation and Campaign 9 UI binding tests |
| Configuration reads normally | pass | Campaign 7 status reused in Settings |
| Secret is not leaked | pass | no-secret scan passed |
| Logs/cache paths are local and non-authoritative | pass | Campaign 9 path rules |
| Failure has user-facing degraded handling | pass | degraded mode matrix |
| No development path dependency claim | pass | status asset records `development_path_dependency_required=false` |
| Optional dependency is not overclaimed | pass | Tauri marked legacy optional, not accepted path |

## UI Binding

Campaign 9 desktop delivery status is visible in Settings under the Desktop Delivery tab. The UI displays build status, rc2 tag target, package checksum, smoke steps, path rules, degraded modes, and security boundaries.

## Final Acceptance Gate

The deliverable can only be marked `campaign9_windows_exe_packaging_accepted_pushed_ci_green_tagged_rc2_pending_release_decision` after Core/UI commits are pushed, remote CI is green, and `v4.3.0-rc2` is created and pushed.
