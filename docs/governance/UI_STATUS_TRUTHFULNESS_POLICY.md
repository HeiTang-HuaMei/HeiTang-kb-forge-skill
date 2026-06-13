# UI Status Truthfulness Policy

UI status must reflect real Core evidence. Static UI, fixture data, or planned adapters must not imply local runtime execution.

## Allowed UI Status Values

- `available`
- `dependency_missing`
- `installing_dependency`
- `install_failed`
- `smoke_pending`
- `smoke_passed`
- `smoke_failed`
- `structured_skipped`
- `reference_only`
- `needs_strengthening`
- `stop_integration`

## Prohibited Claims

The UI must not display `ready`, `passed`, or `available` for a backend unless real dependency check and smoke evidence has passed for that backend in the current or referenced evidence context.

## Required Distinctions

The UI must distinguish:

- dependency is missing
- dependency installation is in progress
- dependency install failed
- smoke has not run
- smoke passed
- smoke failed
- structured skipped was emitted
- adapter is reference only
- adapter needs strengthening
- adapter integration was stopped

## Static Web Boundary

Static web builds may display evidence and reports, but must not claim they execute local CLI or bundled runtimes unless a desktop bridge allowlist and runtime check prove the action is available.

## Full Gate Precheck

Before Full Gate, verify UI status evidence does not overclaim backend readiness and that stale `.codex` recovery or sub-agent runtime state has been cleared or archived.

## Acceptance

Validation must cover allowed UI status values, prohibited ready/passed/available overclaims, static web execution boundary, and backend status mapping from Core evidence.
