# Release Notes

## v4.0.0-rc.1

This release candidate starts after P1 Final Gate Re-run, Pre-v4 External Project Registry, and S/A Contract Inclusion have completed. Core pre-v4 RC readiness remains complete. The latest Core P0 proof reports `ready_for_v4_rc=true` and `P0 blockers=0`, and the latest P1 final gate re-run also reports `ready_for_v4_rc=true`.

This is not the stable `v4.0.0` release. Stable `v4.0.0` requires rc.1 acceptance and hardening evidence.

## Current Main

## P1 Final Gate Re-run

- Added `docs/audits/p1_final_gate_rerun/`.
- Re-verified P1-RWF-V1, P1-RWF-V2, 57 ready local action executions, 10 user paths, UI consumption, drift count, and provider/secret/network blocked boundaries.
- Promoted `ready_for_v4_rc_candidate=true` to `ready_for_v4_rc=true` without starting v4.0, creating a tag, or writing a release.

## P0.6 GitHub Documentation Governance

- Slimmed the GitHub-facing documentation surface.
- Kept current product entry points, current truth, command usage, version matrix, final architecture truth, final gate JSON, and latest P0 proof.
- Moved historical version details back to git history and tags instead of keeping them as top-level docs on main.
- Added documentation governance and README link checks.
