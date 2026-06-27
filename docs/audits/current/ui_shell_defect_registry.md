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
commit_id = 7ab3ce5
```

Evidence already established:

```text
UI008_DeleteTmp_visible_in_running_ui = true
manifest_current_workbook = UI008_DeleteTmp
cold_restart_active_workspace_recovery = true
capability_chain_status_json_unchanged = true
```

### UISHELL-S1-003

```text
defect_id = UISHELL-S1-003
severity = S1
module = UI shell / Document Generation page state
page = Document Generation -> Export Preview
user_path = open top-level Document Generation -> open Export Preview -> inspect local export artifact wording
expected_behavior = Document export artifact wording must tell users that local exports write a file and an export manifest/list; it must match the product task chain and not drift to vague "export info"
actual_behavior = campaign_4 regression failed because the current dirty UI text changed "生成本地文件与导出清单" to "生成本地文件与导出信息"; the export manifest detail row also still used "导出信息 / Export info"
root_cause_category = copy_contract_drift
root_cause_evidence = docs/design_source/USER_TASK_CHAIN_DESIGN.md requires generated documents to show file, format, save location, open/export/delete; the existing test contract expects the export manifest/list wording for local export evidence
minimal_fix_scope = restore manifest/list wording in web/workbench/flutter_app/lib/features/document_generation/document_generation_product_workflow.dart without changing generation logic, gates, or state machine
white_box_result = pass
black_box_result = pass
regression_result = pass
commit_id = dfe3af8
```

Evidence:

```text
source_label = web/workbench/flutter_app/lib/features/document_generation/document_generation_product_workflow.dart:1152 -> 生成本地文件与导出清单 / Writes local file and manifest
source_manifest_row = web/workbench/flutter_app/lib/features/document_generation/document_generation_product_workflow.dart:1345 -> 导出清单 / Export manifest
head_contract = HEAD already preserves manifest/list wording; current dirty drift was restored to that product contract before validation
targeted_test = output/module_repair/phase2_ui_shell/phase2_documents_top_level_test_after_manifest_head_restore.log -> All tests passed
full_campaign_4_regression = output/module_repair/phase2_ui_shell/phase2_campaign_4_full_after_manifest_head_restore.log -> All tests passed
running_ui_method = flutter run -d windows
running_ui_meta = output/module_repair/phase2_ui_shell/phase2_doc_generation_manifest_restart_meta_20260627_230504.json
running_ui_pid = 31372
running_ui_git_head = ce4e0ad
running_ui_dirty_marker = true
running_ui_workspace = UI008_DeleteTmp
running_ui_visible_page = 文档生成
running_ui_visible_tab = 导出预览
running_ui_visible_panel = 文档导出
running_ui_visible_artifact_copy = 生成本地文件与导出清单
running_ui_visible_manifest_row = 导出清单
running_ui_forbidden_old_copy_visible = false
capability_chain_status_json_unchanged = true
```

Disturbance recorded:

```text
intermediate_workspace_created = 新知识工作
auto_deleted = false
reason_not_deleted = not a UI008_ test marker
```

### UISHELL-S1-002

```text
defect_id = UISHELL-S1-002
severity = S1
module = UI shell / Knowledge Base page language state
page = Knowledge Base
user_path = switch running UI to English -> open Knowledge Base -> inspect primary build action
expected_behavior = English Knowledge Base page uses the design-source user action wording "Generate Knowledge Base"; old or implementation-like wording must not remain visible
actual_behavior = widget regression previously failed when the expected English action was missing; fresh running UI now shows the English Knowledge Base page with the disabled "Generate Knowledge Base" action when no source materials exist
root_cause_category = copy_contract_drift
root_cause_evidence = docs/design_source/I18N_AND_COPYWRITING_SPEC.md keeps the ordinary user action as generate/build knowledge base; merge-only copy is reserved for "Merge into new KB"
minimal_fix_scope = restore the Knowledge Base primary action label in web/workbench/flutter_app/lib/features/knowledge_base/knowledge_base_product_workflow.dart without changing gates or state machine
white_box_result = pass
black_box_result = pass
regression_result = pass
commit_id = ce4e0ad
```

Evidence:

```text
source_label = web/workbench/flutter_app/lib/features/knowledge_base/knowledge_base_product_workflow.dart:730 -> Generate Knowledge Base
old_copy_scan = rg found no "Create new Knowledge Base" in lib/ or test/
widget_test = output/module_repair/phase2_ui_shell/phase2_english_mode_test_after_kb_copy_fix.log -> All tests passed
analyze = output/module_repair/phase2_ui_shell/phase2_flutter_analyze_after_kb_copy_fix.log -> No issues found
running_ui_method = flutter run -d windows
running_ui_meta = output/module_repair/phase2_ui_shell/phase2_running_ui_restart_meta_20260627_224407.json
running_ui_pid = 11504
running_ui_git_head = 7ab3ce5
running_ui_dirty_marker = true
running_ui_workspace = UI008_DeleteTmp
running_ui_visible_page = Knowledge Base
running_ui_visible_tabs = Overview, Sources, Verification
running_ui_visible_primary_action = Generate Knowledge Base
running_ui_forbidden_old_copy_visible = false
capability_chain_status_json_unchanged = true
```
