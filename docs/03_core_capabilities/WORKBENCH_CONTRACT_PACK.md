# P1 Workbench Contract Pack

The P1 Workbench contract pack is a Core-only productization surface for a future Windows desktop Workbench UI. It does not implement visual UI, start v4.0, or claim complete Workbench operation.

Generate the deterministic contract pack:

```powershell
python -m heitang_kb_forge.cli workbench-contracts --profile p1 --output .\tmp_workbench_p1
python -m heitang_kb_forge.cli workbench-action-inspect --action-id inspect_dashboard_status
python -m heitang_kb_forge.cli workbench-action-dry-run --action-id inspect_dashboard_status --output .\tmp_workbench_p1_dry_run
python -m heitang_kb_forge.cli workbench-smoke --output .\tmp_workbench_p1_smoke
```

The pack writes:

- `workbench_manifest.json`
- `workbench_action_contracts.json`
- `workbench_capability_matrix.json`
- `workbench_report_registry.json`
- `workbench_artifact_registry.json`
- `workbench_error_taxonomy.json`
- `workbench_task_schema.json`
- `workbench_provider_schema.json`
- `workbench_storage_schema.json`
- `workbench_workspace_schema.json`
- `workbench_template_registry.json`
- `workbench_p1_gate_report.json`
- `workbench_fixture_bundle.json`
- `workbench_productization_schema.json`
- `workbench_summary.md`

The 16 capability areas are Dashboard, Workspace, Import & Parsing, Knowledge Package Management, Retrieval & Verification, Vector Hub / Provider / Storage, Document Generation, Skill Factory, Agent Factory & Runtime, Memory Center, Governance, Template Library, Reports & Audit, Error Repair Center, Task / Job Center, and Artifact Management.

Actions that map to existing Core CLI commands are marked `ready`. UI-safe inspect and dry-run actions are marked `dry_run`. Capabilities that are not a runnable closed loop are marked `planned_adapter`, `ui_pending`, or `blocked` with `blocked_reason`.

The P1 gate is intentionally honest: `core_contract_ready=true`, `ui_full_operation_pending=true`, `p1_full_operation_gate_status=blocked`, and `not_v4_0_workbench_rc=true`.
