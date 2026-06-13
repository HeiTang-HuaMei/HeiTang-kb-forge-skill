# Dependency Remediation Policy

This policy is part of Codex Long-Run Governance, Adapter Integration Governance, and Release Stability Governance. It is a governance rule for adapter and packaging work, not a new business feature scope.

## Rule

Local dependency download and installation is allowed inside the approved project scope when a missing dependency blocks parser, OCR, Document Understanding, UI packaging, or EXE packaging validation.

Applicable dependency targets include PaddleOCR, MinerU, Docling, Marker, OpenDataLoader, Surya, Unstructured, fallback parser dependencies, packaging dependencies, and UI or EXE packaging dependencies.

## Prohibited Shortcut

Initial missing dependency evidence is not enough to mark an adapter as finally blocked. Do not conclude `blocked_by_dependency`, `reference_only`, or `needs_strengthening` solely because the current machine is missing Java, a Python package, a CLI, model files, or packaging tools.

## Required Flow

1. Run dependency check.
2. Record missing dependencies.
3. Decide whether each dependency is project-approved, safe, and suitable to install.
4. Attempt dependency remediation when allowed.
5. Record install command, version, path, source, risk notes, and rollback steps.
6. Re-run dependency check.
7. Re-run smoke.
8. Decide from post-remediation check and smoke evidence.

## Decision Rules

If remediation succeeds:

- `integration_decision = real_integration`
- `dependency_status = available`
- `runtime_status = available`
- `smoke_status = passed`

If remediation fails:

- `integration_decision = needs_strengthening`
- `dependency_status = blocked_by_dependency`
- `runtime_status = unavailable`
- `smoke_status = skipped`
- `blocker_evidence = install/check failure log`

If dependency installation is not suitable:

- `integration_decision = reference_only` or `stop_integration`
- `reason = dependency too heavy / unsafe / incompatible / not project-approved`

## Required Reports

Every remediation attempt must write:

- `<adapter>_dependency_remediation_report.json`
- `<adapter>_dependency_remediation_report.md`

Required fields:

- `adapter_name`
- `missing_dependencies`
- `install_attempted`
- `install_commands`
- `installed_versions`
- `install_paths`
- `source`
- `risk_notes`
- `rollback_steps`
- `post_install_check_result`
- `post_install_smoke_result`
- `final_decision`

## Acceptance

Validation must cover dependency missing, dependency remediation path, post-install check, post-install smoke when runtime is available, structured failure, and `git diff --check`.
