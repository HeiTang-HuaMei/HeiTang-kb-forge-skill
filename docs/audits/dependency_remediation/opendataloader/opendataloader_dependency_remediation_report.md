# OpenDataLoader Dependency Remediation Report

- Adapter: `opendataloader`
- Install attempted: `true`
- Python runtime: `opendataloader-pdf 2.4.7`
- Java runtime: `Temurin 21.0.11+10 LTS`
- Java source: Eclipse Adoptium official API and release asset
- SHA-256 verified: `true`
- Global PATH modified: `false`
- Registry modified: `false`
- User Java environment modified: `false`
- Post-install check: `available`
- Post-install smoke: `pass`
- Runtime status: `available`
- Smoke status: `passed`
- Final decision: `real_integration`
- Blocker evidence: none

## Runtime Evidence

- `java -version` exited `0`.
- `check-opendataloader-backend` exited `0`.
- `smoke-opendataloader-backend` exited `0`.
- The adapter invoked the real runtime.
- The valid PDF produced Markdown and JSON output.
- Extracted text length: `87`.

## Isolation

`JAVA_HOME` and `PATH` were injected only into the check/smoke PowerShell process. The portable JRE is stored under `_local_dependency_remediation/opendataloader/java`.

## Rollback

- Remove `_local_dependency_remediation/opendataloader/java`.
- Remove the downloaded JRE ZIP.
- Remove the isolated Python environment or uninstall `opendataloader-pdf`.
- Re-run the backend check.

## Goal Drift Review

- `final_target_not_downgraded`: `true`
- `remaining_gap`: Marker remediation and smoke, then the mixed document-to-knowledge E2E chain.
- `next_required_e2e_step`: complete Marker remediation, then run batch import -> document understanding -> knowledge base build -> knowledge package build.
- `not_goal_complete`: `true`
