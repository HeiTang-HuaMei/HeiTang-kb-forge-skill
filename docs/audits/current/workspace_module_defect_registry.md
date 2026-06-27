# Workspace Module Defect Registry

## Scope

- Phase: Module-by-Module Post-Closure UI Bug Repair Plan / Phase 3
- Module covered now: workspace create, switch, delete, recreate, restart recovery, and workbook asset truth path
- Rule source: `docs/design_source/WORKSPACE_AND_DATA_MODEL_DESIGN.md`, `docs/design_source/SERVICE_CONTRACTS.md`
- Boundary: S0/S1 only; do not enter Final Owner Review Gate; do not modify `capability_chain_status.json`

## Defects

### WORKSPACE-S1-001

```text
defect_id = WORKSPACE-S1-001
severity = S1
module = Workspace
page = runtime/controller workspace chain
user_path = create temporary workbook -> delete it -> create recovery workbook -> import sources -> generate KBs -> reload -> merge/delete merged KB safely
expected_behavior = backend truth checks follow the active workbook workspace path after create/switch; repeated file/folder import keeps one source record for identical files; separate selected sources generate separate KB records; imported sources, KBs, package export, merge, delete, and reload all remain inside the current workbook asset directory
actual_behavior = clean HEAD plus the Phase 1B lifecycle E2E copied repeated folder imports into alpha-1.md and beta-1.txt; after import dedupe, clean staged snapshot still produced only K1 when alpha and beta were built separately; the first draft oracle also checked root workspace/input and root workspace/knowledge_bases after switching to Phase 1B 恢复工作区, producing a PathNotFoundException and weakening workbook isolation evidence
root_cause_category = state_not_persisted
root_cause_evidence = Rc6RuntimeController._copySourceIntoInput always generated a suffixed target when the same relative path already existed; _writeKnowledgeBaseCatalog reused existing.first.kb_id for later builds instead of creating a new KB for a different source signature; Rc6RuntimeController also sets state.workspacePath to workbooks/assets/<current workbook> after createOrSwitchWorkbook, so the E2E oracle must assert against controller.state.workspacePath
minimal_fix_scope = make _copySourceIntoInput reuse an existing target only when source and target bytes match; make _writeKnowledgeBaseCatalog reuse a KB only for the same source signature and create K2/K3 for different selected sources; update the Phase 1B E2E oracle to use controller.state.workspacePath for input and knowledge_bases checks
white_box_result = pass
black_box_result = covered by existing running UI workspace-chain recovery evidence
regression_result = pass
commit_id = this commit
```

Evidence:

```text
failing_test_before_fix = output/module_repair/module3_workspace/module3_phase1b_workspace_import_kb_lifecycle.log -> PathNotFoundException on root workspace/input
staged_snapshot_before_runtime_fix = output/module_repair/module3_workspace/module3_phase1b_workspace_import_kb_lifecycle_staged_snapshot.log -> duplicate alpha-1.md and beta-1.txt on clean HEAD plus E2E
staged_snapshot_after_import_dedupe_before_catalog_fix = output/module_repair/module3_workspace/module3_phase1b_workspace_import_kb_lifecycle_staged_snapshot_after_runtime_fix.log -> only K1 after separate alpha/beta builds on clean staged snapshot
targeted_test_after_fix = output/module_repair/module3_workspace/module3_phase1b_workspace_import_kb_lifecycle_staged_snapshot_after_catalog_fix.log -> All tests passed
workspace_delete_restart_regression = output/module_repair/module3_workspace/module3_prd_workbook_deletion_persists_staged_snapshot_after_catalog_fix.log -> All tests passed
code_quality_gate = output/module_repair/module3_workspace/module3_flutter_analyze_staged_snapshot_after_catalog_fix.log -> No issues found
running_ui_workspace_chain = docs/audits/current/workspace_chain_runtime_evidence.md
running_ui_workspace = UI008_DeleteTmp
backend_manifest_current_workbook = UI008_DeleteTmp
capability_chain_status_json_unchanged = true
```

### WORKSPACE-S1-002

```text
defect_id = WORKSPACE-S1-002
severity = S1
module = Workspace
page = runtime/controller workspace lifecycle
user_path = create workbook -> switch workbook -> delete workbook -> restart -> inspect operation evidence
expected_behavior = workspace create/switch/delete writes durable Event Ledger records so restart recovery and support diagnostics can explain who changed the active workspace and what was deleted
actual_behavior = clean HEAD plus the workbook event-ledger E2E did not create audit/event_ledger.jsonl for workbook create/switch/delete, so the workspace manifest changed without operation evidence
root_cause_category = event_not_recorded
root_cause_evidence = Rc6RuntimeController.createOrSwitchWorkbook and deleteWorkbook updated workbook_manifest.json and runtime state but never called _appendEventLedgerRecord on the successful path
minimal_fix_scope = append workspace_lifecycle Event Ledger records for successful create_workbook and delete_workbook operations; add a targeted restart-readable ledger E2E
white_box_result = pass
black_box_result = covered by existing running UI workspace-chain recovery evidence
regression_result = pass
commit_id = this commit
```

Evidence:

```text
failing_test_before_fix = output/module_repair/module3_workspace/module3_workbook_event_ledger_before_fix.log -> ledger.existsSync expected true, actual false
targeted_test_after_fix = output/module_repair/module3_workspace/module3_workbook_event_ledger_after_fix.log -> All tests passed
workspace_delete_restart_regression = output/module_repair/module3_workspace/module3_prd_workbook_deletion_persists_after_event_ledger_fix.log -> All tests passed
code_quality_gate = output/module_repair/module3_workspace/module3_flutter_analyze_after_workbook_event_ledger_fix.log -> No issues found
capability_chain_status_json_unchanged = true
```
