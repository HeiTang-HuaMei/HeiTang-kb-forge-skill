# Document Library / Import Module Defect Registry

## Module Status

- module: Document Library / Import Module
- current_status: module_4_s0_s1_repair_in_progress
- boundary: UI closure repair only; Final Owner Review Gate not entered
- state_machine_changed: false
- package_build_run: false

## DOCUMENT-IMPORT-S1-001

- defect_id: DOCUMENT-IMPORT-S1-001
- severity: S1
- module: Document Library / Import Module
- page: Document Library / Import
- user_path: import file / folder -> inspect source manifest -> delete source -> restart recovery
- expected_behavior: verifier reads the same active workspace that the runtime uses for source_manifest.json, input files, generated cleanup, and restart state
- actual_behavior: two Module 4 regression tests read source_manifest.json and stale kb artifacts from the configured workspace root after the workbook lifecycle repair moved active product data under the current workspace path exposed by controller state
- reproduce_steps: run `flutter test test/rc6_runtime_truth_blocker_repair_test.dart --name "rc10 importing another file appends|rc10 deleting one imported source|phase 1b workspace import kb lifecycle"`
- exact_error: PathNotFoundException for `<temp workspace>/source_manifest.json`
- root_cause_category: test_or_verifier_wrong
- root_cause_evidence: runtime writes and exposes import artifacts through `controller.state.workspacePath`; failing tests still used the configured root `workspace.path` for source_manifest/input/kb assertions
- minimal_fix_scope: update only the affected verifier assertions to resolve paths from `Directory(controller.state.workspacePath)` after initialization
- allowed_files: `web/workbench/flutter_app/test/rc6_runtime_truth_blocker_repair_test.dart`, this registry
- forbidden_files: `capability_chain_status.json`, P0/P1/P2 gate reports, package/build artifacts
- white_box_result: pass
- black_box_result: pass
- regression_result: pass
- commit_id: this commit

Evidence:

```text
failing_test_before_fix = output/module_repair/module4_document_import/module4_baseline_existing_import_delete.log -> PathNotFoundException on root source_manifest.json
working_tree_targeted_after_fix = output/module_repair/module4_document_import/module4_baseline_existing_import_delete_after_fix.log -> All tests passed
staged_snapshot_targeted_after_fix = output/module_repair/module4_document_import/module4_staged_snapshot_import_delete_after_fix.log -> All tests passed
staged_snapshot_code_quality = output/module_repair/module4_document_import/module4_staged_snapshot_flutter_analyze_after_fix.log -> No issues found
capability_chain_status_json_unchanged = true
```

## Current Counts

- defect_count: 1
- S0_count: 0
- S1_count: 1
- S2_count: 0
- S3_count: 0
- fixed_defects: DOCUMENT-IMPORT-S1-001
- remaining_defects: Module 4 fixed-sample matrix still to be audited after this verifier repair
