# UI Shell Targeted Fix Queue

## Scope

- Phase: Module-by-Module Post-Closure UI Bug Repair Plan / Phase 2
- Queue policy: S0/S1 only in this round
- Boundary: no package build, no Final Owner Review Gate, no P2 reopen, no `capability_chain_status.json` change

## Queue

### 1. UISHELL-S1-001

```text
status = verified
defect = workspace_chain recreate and cold restart recovery
source = docs/audits/current/workspace_chain_runtime_evidence.md
next_action = none for this checkpoint
```

Retest steps completed:

```text
1. Use the current running UI Workspace page.
2. Enter UI008_DeleteTmp through the visible Workspace page field.
3. Activate the visible create/switch action.
4. Confirm the visible UI shows UI008_DeleteTmp as current workspace.
5. Reconcile C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace\workbooks\workbook_manifest.json.
6. Cold restart latest Debug app from source.
7. Confirm Owner-visible UI and backend manifest agree after restart.
```

Pass criteria:

```text
recreate_workspace_through_running_ui = true
manifest_current_workbook = UI008_DeleteTmp
cold_restart_active_workspace_recovery = true
owner_visible_ui_after_recreate = true
capability_chain_status_json_unchanged = true
```

### 2. UISHELL-S1-002

```text
status = verified
defect = English Knowledge Base page primary build action copy drift
source = docs/design_source/I18N_AND_COPYWRITING_SPEC.md
next_action = none for this checkpoint
```

Retest steps completed:

```text
1. Confirm no capability_chain_status.json diff.
2. Use fresh running UI launched by flutter run -d windows.
3. Confirm running process is heitang_workbench.exe from the Debug runner.
4. Switch the Owner-visible UI from Chinese to English.
5. Open the left navigation Knowledge Base page.
6. Confirm the page title is Knowledge Base.
7. Confirm visible tabs include Overview, Sources, and Verification.
8. Confirm the primary disabled build action reads Generate Knowledge Base.
9. Confirm old copy Create new Knowledge Base is not visible in running UI evidence and not present in lib/test source scan.
```

Pass criteria:

```text
running_ui_verified_latest = true
owner_visible_ui_tested = true
knowledge_base_page_loaded_in_english = true
primary_action_copy = Generate Knowledge Base
old_create_new_kb_copy_absent = true
widget_test_passed = true
flutter_analyze_passed = true
capability_chain_status_json_unchanged = true
```

### 3. UISHELL-S1-003

```text
status = verified
defect = Document Generation export preview drifted from export manifest/list wording to vague export info wording
source = docs/design_source/USER_TASK_CHAIN_DESIGN.md
next_action = none for this checkpoint
```

Retest steps completed:

```text
1. Confirm no capability_chain_status.json diff.
2. Reproduce with campaign_4 full UI shell regression: documents are a first-class top-level workbench entry failed on missing 生成本地文件与导出清单.
3. Restore only Document Generation export preview copy to 生成本地文件与导出清单 / Writes local file and manifest.
4. Restore export detail field wording to 导出清单 / Export manifest.
5. Run targeted documents top-level test.
6. Run full campaign_4 UI shell regression.
7. Close stale heitang_workbench.exe.
8. Launch fresh running UI with flutter run -d windows.
9. Open Owner-visible 文档生成 page.
10. Open 导出预览.
11. Confirm visible 文档导出 table shows 生成本地文件与导出清单.
12. Confirm visible manifest row shows 导出清单 and old 生成本地文件与导出信息 / 导出信息 copy is not visible.
```

Pass criteria:

```text
running_ui_verified_latest = true
owner_visible_ui_tested = true
document_generation_top_level_entry_loaded = true
export_preview_loaded = true
local_export_copy = 生成本地文件与导出清单
export_manifest_row = 导出清单
old_export_info_copy_absent = true
targeted_widget_test_passed = true
campaign_4_full_regression_passed = true
capability_chain_status_json_unchanged = true
```
