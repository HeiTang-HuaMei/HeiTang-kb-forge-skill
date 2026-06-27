# Workspace Chain Runtime Evidence

## Scope

- Module: Workspace chain
- Checkpoint: `UI008_DeleteTmp` delete / recreate / cold restart recovery
- Evidence time: 2026-06-27
- Boundary: no Final Owner Review Gate, no package build, no P2 reopen, no `capability_chain_status.json` change

## Current Provenance

```text
running_ui_method = flutter run -d windows
app_process_id_before_restart = 26732
app_process_id_after_restart = 36980
app_path = D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\build\windows\x64\runner\Debug\heitang_workbench.exe
git_head = 2ddeca1
dirty_marker = true
capability_chain_status_json_unchanged = true
cold_restart_meta = D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\output\module_repair\phase2_ui_shell\workspace_chain_restart_meta_20260627_222617.json
```

The running UI was observed at the Task Workbench page and then at the Workspace page. After cold restart, the new running UI restored `UI008_DeleteTmp`.

## Backend Truth

```text
manifest_path = C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace\workbooks\workbook_manifest.json
current_workbook = UI008_DeleteTmp
workbook_count = 4
workbooks = 新知识工作本 | UI008_Phase3_Workbook_TestMarked | 新知识工作 | UI008_DeleteTmp
UI008_DeleteTmp_present = true
UI008_DeleteTmp_status = active
```

## What Is Proven

```text
delete_temporary_workspace_record_backend_reconciled = true
recreate_workspace_through_running_ui = true
manifest_current_workbook = UI008_DeleteTmp
cold_restart_active_workspace_recovery = true
owner_visible_ui_after_recreate = true
state_machine_unchanged = true
workspace_chain_closed = true
```

The temporary test workbook `UI008_DeleteTmp` was recreated through the latest running UI, reconciled against the authoritative workbook manifest, and restored after cold restart.

## Running UI Evidence

```text
before_restart_visible_location = UI008_DeleteTmp
before_restart_visible_current_workbook = UI008_DeleteTmp
after_restart_visible_location = UI008_DeleteTmp
after_restart_visible_current_workbook = UI008_DeleteTmp
after_restart_visible_summary = UI008_DeleteTmp · 等待导入资料
```

The running UI accessibility tree after restart showed the fixed primary navigation:

```text
导入资料
知识库
Skill
Agent
文档生成
任务工作台
配置
```

## Disturbance Note

During input troubleshooting, an intermediate workbook named `新知识工作` was created by the running UI before the target test marker was entered successfully.

```text
disturbance_workspace = 新知识工作
auto_deleted = false
reason_not_deleted = not a UI008_ test marker, so no automatic deletion
```

## Closure

This checkpoint is closed for the workspace chain:

```text
delete_temporary_workspace_record_through_running_ui = previously_reconciled
recreate_workspace = pass
cold_restart_restore = pass
current_workspace_matches_backend_after_restart = pass
```
