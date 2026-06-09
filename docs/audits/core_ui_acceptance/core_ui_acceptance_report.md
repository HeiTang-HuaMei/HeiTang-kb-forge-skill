# Core x UI Acceptance Report

Generated: 2026-06-09

Scope: Core x UI combination acceptance, drift check, real path validation, and report generation.

## Result

Status: blocked.

This is not full operation yet and not the v4.0 Workbench RC. The UI now treats Core actions as executable only when they match an explicit local path policy, and keeps unsupported provider, secret, planned adapter, network, and web-local-CLI actions disabled with `blocked_reason`.

## Action Classification

- Total Core actions: 110.
- Real local workflow actions: 57.
- Deterministic smoke actions: 36.
- Disabled blocked actions: 17.
- Web-enabled actions: 0.

Policy:

- Real local workflow: `status == ready && command_kind == core_cli && desktop_enabled == true`.
- Deterministic smoke: `status == dry_run && command_kind == ui_safe_wrapper && desktop_blocked_reason == mock_only`.
- All other actions: no `CoreBridgeRequest`; render disabled with `blocked_reason`.
- Web/static runtime: disabled with `web_local_cli_unsupported`.

## Drift Check

Core contracts were regenerated from:

`python -m heitang_kb_forge.cli_runtime workbench-contracts --profile p1 --output ../_tmp_goal_core_contracts_ui_acceptance`

Verified Core commit: `533fc9267934dc8080a12ba018602e2f226bd385`.

Drift status: pass.

The UI fixture and Flutter asset match each other. Core fields in actions, reports, artifacts, errors, templates, capability matrix, task schema, and gate report match the regenerated Core contracts. UI-only action fields are limited to route and runtime blocked/enabled metadata.

## Real Path Validation

Desktop path:

Flutter action panel -> `CoreBridgeRequest` -> `LocalCoreBridge` allowlist -> `dart:io Process.run(runInShell:false)`.

Validated:

- 57 real local Core CLI actions build allowlisted bridge requests.
- 36 deterministic smoke actions build allowlisted bridge requests.
- 17 blocked actions build no bridge request and keep blocked reasons visible.
- Web/static action buttons stay disabled with blocked reasons.
- Shell metacharacters are rejected.
- Secret environment keys are rejected.
- Command output is redacted.
- Real Core CLI smoke passed with `heitang-kb-forge workbench-smoke --output ../_tmp_goal_core_smoke`; Core still reports `Gate: blocked`.

Remaining risk: the full business-input execution of all 57 ready Core actions has not been completed. That requires prepared local workspace inputs and per-action artifact assertions, so the P1 gate remains blocked.
