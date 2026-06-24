# Worktree Gate Commit Triage

Status: worktree_triage_in_progress

## Scope

This note inventories the current dirty worktree before local commits. It does not clean files and does not claim product acceptance.

## Current Inventory

- Tracked modified files: 26.
- Approximate tracked diff: 8769 insertions, 1997 deletions.
- Untracked audit reports: 15.
- Untracked verifier scripts: 7.
- `web/workbench/flutter_app/output/` is ignored by `.gitignore`; reports reference local output evidence, but the output directory has no tracked files.
- `git diff --check` exit code: 0. Only CRLF warnings were reported.

## Gate Grouping

### Agent P0 Runtime And Evidence

Likely files:

- `web/workbench/flutter_app/lib/features/agent/agent_product_workflow.dart`
- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`
- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_stub.dart`
- `web/workbench/flutter_app/lib/main.dart`
- `docs/audits/current/agent_module_runtime_inventory.md`
- `docs/audits/current/agent_runtime_p0_repair_report.md`
- `docs/audits/current/agent_p0_exe_blackbox_lifecycle_report.md`

Validation already recorded in the Agent report; rerun narrow Flutter checks before commit.

### Event Ledger And Artifact Lifecycle

Likely files:

- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`
- `web/workbench/flutter_app/lib/features/dashboard/dashboard_product_workflow.dart`
- `web/workbench/flutter_app/lib/features/artifacts/artifact_center_product_workflow.dart`
- `web/workbench/flutter_app/lib/features/audit/audit_center_product_workflow.dart`
- `docs/audits/current/event_ledger_repair_report.md`
- `docs/audits/current/artifact_lifecycle_repair_report.md`

The runtime file overlaps heavily with Agent, document library, knowledge base, artifact, and connector work. Use caution when staging partial hunks.

### Document Library Lifecycle

Likely files:

- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`
- `web/workbench/flutter_app/lib/features/document_library/document_library_product_workflow.dart`
- `web/workbench/flutter_app/lib/features/import_parsing/import_product_workflow.dart`
- `docs/audits/current/document_library_blackbox_report.md`

### Knowledge Base Build And Validation

Likely files:

- `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`
- `web/workbench/flutter_app/lib/features/knowledge_base/knowledge_base_product_workflow.dart`
- `web/workbench/flutter_app/lib/features/retrieval/retrieval_verification_product_workflow.dart`
- `docs/audits/current/knowledge_base_build_blackbox_report.md`
- `docs/audits/current/knowledge_validation_blackbox_report.md`

Current local cleanup evidence: `kb_catalog.json` has zero knowledge bases, K1/K2 directories are absent, and latest event is `delete_knowledge_base` for K1.

### UI Layout And Navigation

Likely files:

- `web/workbench/flutter_app/lib/app/*`
- `web/workbench/flutter_app/lib/shared/product_components.dart`
- `web/workbench/flutter_app/lib/shared/workbench_layout.dart`
- `web/workbench/flutter_app/lib/features/dashboard/dashboard_product_workflow.dart`
- `docs/audits/current/global_ui_style_system_optimization_report.md`
- `docs/audits/current/ui_button_runtime_mapping_matrix.md`
- `docs/audits/current/ui_responsive_layout_repair_report.md`

This slice is visually broad and should not be mixed into runtime capability commits unless required by compilation.

### Verifier Scripts

Likely files:

- `web/workbench/flutter_app/tool/windows_native_product_verifier/*.ps1`

Untracked verifier scripts should be committed only if they are referenced by a current report or needed for repeatable validation.

## Evidence Handling

- Keep local `output/` evidence in place.
- Do not delete screenshots, matrices, or logs that reports reference.
- Do not force-add the whole `output/` tree.
- If a matrix must be versioned, add only that specific JSON with `git add -f`.

## Recommended Commit Order

1. Agent P0 runtime and evidence.
2. Event Ledger and Artifact Lifecycle runtime/evidence.
3. Document Library lifecycle.
4. Knowledge Base build and validation lifecycle.
5. UI/layout/verifier scripts.
6. Audit report cleanup only after the above slices are stable.

## Guardrails

- Do not run `git reset --hard`.
- Do not run `git clean -fd`.
- Do not create one large mixed commit.
- Each commit should run `git diff --check` first and record the narrow validation used.
