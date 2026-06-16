# Campaign 9 Release Blockers and Known Limitations

Date: 2026-06-17

Status: local validation passed, pending remote CI and rc2 tag

## Current Blockers

| Blocker | Status | Note |
| --- | --- | --- |
| Local Windows build | cleared | `flutter build windows` passed |
| Desktop shell smoke | cleared | launch/minimize/restore/maximize/resize/close passed |
| Bundle checksum | cleared | EXE SHA-256 recorded |
| Local validation gates | cleared | UI Python, Flutter, Core pytest, scans, and diff check passed |
| Remote CI | pending | Must pass before rc2 tag |
| GitHub Release | intentionally not created | Owner authorization required |

## Known Limitations

| Limitation | Boundary |
| --- | --- |
| `v4.3.0-rc2` is a delivery candidate tag, not a stable release decision | stable `v4.3.0` requires Owner authorization |
| Provider-backed features still require env/secret-store setup | no secret is bundled |
| Clean-machine smoke is limited by the current local environment | plan and local evidence are recorded; external machine evidence can be added later |
| Legacy Tauri scaffold exists outside the accepted path | not accepted as Campaign 9 package |
| Computer Use remains disabled | future implementation requires a separate gate |

## Release Boundary

No GitHub Release is created in Campaign 9. The next allowed release action is Owner review after rc2 tag and CI green.
