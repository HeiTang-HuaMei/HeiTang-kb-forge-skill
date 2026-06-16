# Campaign 9 Packaging Degraded Mode and Rollback Matrix

Date: 2026-06-17

Status: pass

## Degraded Mode Matrix

| Condition | Runtime Status | User-Facing Handling | Acceptance Impact |
| --- | --- | --- | --- |
| missing provider env | degraded | Keep provider-backed actions disabled and show repair guidance | accepted if local desktop shell remains usable |
| workspace path unavailable | blocked | Prompt for a valid workspace path before local workflows start | blocks workflow execution |
| required bundle file missing | blocked | Do not mark package accepted until bundle is rebuilt | blocks Campaign 9 acceptance |
| desktop shell smoke failure | blocked | Repair shell behavior and rerun real smoke | blocks Campaign 9 acceptance |
| GitHub Release requested | blocked pending Owner | Require separate Owner authorization | no release created by default |
| Computer Use requested | disabled boundary | Keep OS/browser/screen/keyboard/mouse automation disabled | hard stop if enabled |

## Rollback Matrix

| Area | Rollback |
| --- | --- |
| Package artifact | Discard candidate bundle and rebuild from the accepted commit |
| Config profile | Use Campaign 7 rollback snapshots and preserve diagnostics |
| Workspace state | Smoke should not mutate workspace data; restore from user backup if a later workflow mutates data |
| Tag policy | Do not move or force-push tags; create a new authorized candidate only after Owner review |
| UI status | Revert only Campaign 9 UI status asset and Settings binding if the desktop evidence is invalidated |

## Hard Stop Boundary

Campaign 9 must stop if any secret exposure, path containment failure, arbitrary shell enablement, Computer Use runtime enablement, or unauthorized release action is detected.
