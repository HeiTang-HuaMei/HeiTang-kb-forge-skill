# P1 Workbench Contract Pack

P1 Workbench contract pack 是 Core-only 的产品化接口层，用于支撑未来 Windows desktop Workbench UI。它不实现视觉 UI、不启动 v4.0，也不声明完整 Workbench operation。

生成确定性 contract pack：

```powershell
python -m heitang_kb_forge.cli workbench-contracts --profile p1 --output .\tmp_workbench_p1
python -m heitang_kb_forge.cli workbench-action-inspect --action-id inspect_dashboard_status
python -m heitang_kb_forge.cli workbench-action-dry-run --action-id inspect_dashboard_status --output .\tmp_workbench_p1_dry_run
python -m heitang_kb_forge.cli workbench-smoke --output .\tmp_workbench_p1_smoke
```

输出文件包括：

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

16 个 capability area 覆盖 Dashboard、Workspace、Import & Parsing、Knowledge Package Management、Retrieval & Verification、Vector Hub / Provider / Storage、Document Generation、Skill Factory、Agent Factory & Runtime、Memory Center、Governance、Template Library、Reports & Audit、Error Repair Center、Task / Job Center 和 Artifact Management。

映射到现有 Core CLI 的 action 标记为 `ready`。UI-safe inspect / dry-run 标记为 `dry_run`。尚不能形成可运行闭环的能力标记为 `planned_adapter`、`ui_pending` 或 `blocked`，并写入 `blocked_reason`。

P1 gate 保持诚实：`core_contract_ready=true`、`ui_full_operation_pending=true`、`p1_full_operation_gate_status=blocked`、`not_v4_0_workbench_rc=true`。
