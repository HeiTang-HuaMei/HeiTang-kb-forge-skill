# UI Shell Defect Registry

## Scope

- Phase: Module-by-Module Post-Closure UI Bug Repair Plan / Phase 2
- Modules covered now: UI shell, navigation, page state, workspace-chain entry
- Rule source: `docs/design_source/DEVELOPMENT_REPAIR_RULES.md`, `docs/design_source/UI_STATE_SPEC.md`
- Boundary: S0/S1 only; do not enter Final Owner Review Gate; do not modify `capability_chain_status.json`

## Defects

### UISHELL-S1-001

```text
defect_id = UISHELL-S1-001
severity = S1
module = UI shell / workspace page state
page = 任务工作台 -> 工作区
user_path = delete UI008_DeleteTmp -> recreate UI008_DeleteTmp -> cold restart restore
expected_behavior = workspace_chain proves delete, recreate, manifest reconciliation, and restart recovery through the latest running UI
actual_behavior = initially blocked by running UI input control; then verified by context-menu paste into the latest running UI and cold restart recovery
root_cause_category = verification_input_method_fragility_resolved
root_cause_evidence = docs/audits/current/workspace_chain_runtime_evidence.md
minimal_fix_scope = no product code change; use verified running UI path, manifest reconciliation, and cold restart recovery
white_box_result = manifest reconciled
black_box_result = pass
regression_result = pass
commit_id = pending
```

Evidence already established:

```text
UI008_DeleteTmp_visible_in_running_ui = true
manifest_current_workbook = UI008_DeleteTmp
cold_restart_active_workspace_recovery = true
capability_chain_status_json_unchanged = true
```

Disturbance recorded:

```text
intermediate_workspace_created = 新知识工作
auto_deleted = false
reason_not_deleted = not a UI008_ test marker
```
