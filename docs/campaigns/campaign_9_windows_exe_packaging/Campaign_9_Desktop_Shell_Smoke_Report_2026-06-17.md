# Campaign 9 Desktop Shell Smoke Report

Date: 2026-06-17

Status: pass

## Smoke Target

| Field | Value |
| --- | --- |
| EXE | `heitang_workbench.exe` |
| Runtime | Flutter Windows runner |
| Evidence JSON | `kb-forge-skill-ui/web/workbench/flutter_app/output/campaign9_desktop_smoke/desktop_shell_smoke.json` |
| Generated at | `2026-06-17T05:06:45.8778281+08:00` |

## Real Shell Steps

| Step | Result |
| --- | --- |
| launch | pass |
| minimize | pass |
| restore after minimize | pass |
| maximize | pass |
| restore after maximize | pass |
| resize | pass |
| close | pass, exit code `0` |

## Acceptance Notes

The smoke test launched the built Windows executable and exercised real desktop shell behavior through window handle operations. This is not a display-only assertion and is not a mock runtime.

## Boundaries

- Smoke did not mutate workspace data.
- Smoke did not require provider secrets.
- Smoke did not enable Computer Use runtime.
- Smoke did not create a GitHub Release.
