# rc13 Stage 2 Runtime Preflight Blocker Report

Date: 2026-06-20

## Scope

This report records the Stage 3 preflight boundary for Provider hot-swap work.

Stage 3 must not load external project runtimes until Stage 2 P0/P1/P2 capabilities are proven as industrial runtime capabilities. Data packages, manifests, candidate layers, and local probe reports are not enough by themselves.

## Decision

Provider candidates may remain visible as user-facing capability enhancements, but external runtime loading is blocked until the Stage 2 industrial preflight passes.

The runtime now writes `stage_2_industrial_preflight` into:

- `config/project_config_runtime_status.json`
- `config/provider_adapter_readiness_report.json`
- `config/provider_capability_binding_manifest.json`
- `config/registered_provider_health_report.json`
- `config/registered_provider_hot_swap_stability_report.json`

The reports also include `external_runtime_load_allowed=false` while the preflight is blocked.

## Runtime-Level Requirements

The preflight requires runtime evidence for:

1. OKF Bundle runtime export/import. Current implementation must prove runtime execution, not only a standard package manifest.
2. OKF runtime to KB build. Current implementation must prove downstream KB materialization, catalog binding, orchestration, and audit records.
3. A2A multi-round collaboration and conflict detection. Current implementation writes runtime evidence.
4. Skill secondary fusion plus multi-version management. Current implementation must prove fusion runtime, independent version snapshots, diff, rollback, and audit records.
5. Agent workspace permission enforcement and unauthorized access blocking. Current implementation must prove real deny/allow authorization cases, not only a static permission matrix.
6. Real 38-step industrial chain smoke pass.
7. Independent Windows EXE launch smoke pass. The 38-step runtime artifact report cannot be used as a substitute for launching the desktop EXE.

## Important Boundary

Standard knowledge package artifacts alone are not treated as OKF runtime completion.

The runtime now requires `standard_packages/okf_runtime_manifest.json` with:

- `schema_version=prd_v3_okf_runtime_manifest.v1`
- `runtime_loaded=true`
- `export_import_runtime_available=true`
- `kb_build_runtime_available=true`

The Stage 2 gate also requires runtime execution evidence outside the manifest:

- `standard_packages/audit_history.jsonl` contains completed OKF export/import and KB build events.
- `orchestration/orchestration_plan.jsonl` contains OKF runtime-enabled orchestration records for OKF export/import and KB build.
- `standard_packages/current/content_package.jsonl` contains real records.
- `kb/manifest.json` is `prd_v3_kb_from_standard_package.v1` and passes.
- `kb/chunks.jsonl` contains materialized chunks.
- `knowledge_bases/kb_catalog.json` binds `K_OKF1` to the source standard package manifest.

This is an internal product runtime for `document_library_to_knowledge_base`. It is not an external OKF service, not an independent Agent runtime, and not a top-level UI page. For P2 industrial completion, OKF must remain invisible as a top-level product module while still being a real runtime capability in the document library to knowledge base path.

## Skill Runtime Boundary

Skill operation manifests alone are not treated as industrial Skill completion.

The Stage 2 gate requires:

- `skill/operations/skill_runtime_manifest.json` with `schema_version=prd_v3_skill_runtime_manifest.v1`.
- `secondary_fusion_runtime_available=true`.
- `multi_version_runtime_available=true`.
- Independent Skill version snapshots under `skill/versions/`.
- `skill/operations/skill_version_diff_report.json` with `status=pass`.
- `skill/operations/skill_rollback_manifest.json` with a real rollback snapshot target.
- `skill/operations/skill_runtime_audit.jsonl` with a `skill_secondary_fusion` event.
- `skill/fused_product_ops_skill/SKILL.md` and `skill_manifest.json` proving `skill_plus_kb_fusion`.

## Agent Permission Runtime Boundary

Agent permission matrices alone are not treated as workspace authorization completion.

The Stage 2 gate requires:

- `agent/audit/workspace_permission_matrix.json` declaring W_A, W_M, W_B, and W_C boundaries.
- `agent/audit/permission_audit.json` linking to the matrix.
- `agent/audit/unauthorized_access_block_report.json` with `status=pass`.
- `agent/audit/authorization_runtime_audit.jsonl` containing allow and deny decisions.
- Denied cases for unauthorized KB access, sibling workspace access, non-allowlisted tools, and plaintext secret access.
- `unauthorized_resources_selectable=false`.
- `agent/audit/agent_validation_report.json` and `agent/audit/run_history.json` linking the authorization runtime evidence.

## EXE Launch Runtime Boundary

The Stage 2 gate now separates product-chain smoke from desktop launch smoke.

The 38-step chain report remains:

- `acceptance/industrial_exe_smoke_report.json`
- `schema_version=prd_v3_industrial_exe_smoke_report.v1`
- `status=passed`
- `step_count>=38`

The EXE launch evidence must be a separate report:

- `acceptance/exe_launch_smoke_report.json`
- `schema_version=prd_v3_exe_launch_smoke_report.v1`
- `status=passed`
- `platform=windows`
- `exe_path` points to an existing `heitang_workbench.exe`
- `launched=true`
- `process_started=true` or `process_id>0`
- `crashed=false`
- `startup_timeout=false`
- `log_path` points to an existing launch log
- `secret_plaintext_written=false`

Helper script:

- `scripts/smoke_windows_exe_launch.ps1`

This keeps the preflight from treating a unit/runtime chain report as proof that the packaged desktop EXE can launch.

## Validation

Validated commands:

```text
dart format lib\rc6_runtime\rc6_runtime_controller_io.dart test\rc6_runtime_truth_blocker_repair_test.dart
flutter analyze
flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1
git diff --check
```

Result:

- `flutter analyze`: passed.
- `rc6_runtime_truth_blocker_repair_test.dart`: 36/36 passed.
- `git diff --check`: only Windows line-ending warnings.
- Secret scan: no plaintext secrets found in this slice.
- OKF runtime scan: standard package files alone do not pass the Stage 2 preflight; runtime execution, audit, orchestration, and downstream KB evidence are required.

## Current Status

Stage 3 Provider hot-swap may continue only as config/readiness/audit hardening.

It must not proceed to external runtime loading or claim registered projects are runtime-integrated until the remaining Stage 2 runtime preflight item passes:

- Independent Windows EXE launch smoke pass.
