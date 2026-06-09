# P1 UI Core Parity

P1 is now the local Workbench evidence gate that has passed for v4 RC readiness. The project has moved into `v4.0.0-rc.1` release candidate preparation; stable `v4.0.0` still requires rc.1 acceptance and hardening evidence.

## Goal

Prove that the UI can guide or operate the same main workflows already proven by Core:

- workspace setup
- file selection
- KB build
- query and verification
- document generation
- Agent and Skill creation
- local runtime flows
- storage and memory lifecycle views
- release and gate report review
- provider settings without committing secrets

## Acceptance Boundary

P1 requires Core V1/V2 evidence, UI consumption, drift-free assets, and explicit provider/secret/network blocked boundaries. Contract views or minimal bridge wiring alone are not enough.

## Current Status

- Core pre-v4 RC readiness is complete.
- P1-RWF-V2 evidence and UI consumption have been re-run into `ready_for_v4_rc=true`.
- `v4.0.0-rc.1` release candidate preparation is current; stable `v4.0.0` is not released.
