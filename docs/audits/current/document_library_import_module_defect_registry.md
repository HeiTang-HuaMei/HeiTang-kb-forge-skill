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

## Module 4 Evidence Without New Defect

```text
unsupported_import_explainable_failure = output/module_repair/module4_document_import/module4_unsupported_import_evidence_working_tree.log -> All tests passed
unsupported_import_staged_snapshot = output/module_repair/module4_document_import/module4_staged_snapshot_unsupported_import_evidence.log -> All tests passed
unsupported_import_staged_analyze = output/module_repair/module4_document_import/module4_staged_snapshot_unsupported_flutter_analyze.log -> No issues found
unsupported_import_result = no new S0/S1; unsupported .exe import is rejected before core execution, source_manifest is not created, and failure_event is written to Event Ledger
```

## Current Counts

- defect_count: 3
- S0_count: 0
- S1_count: 3
- S2_count: 0
- S3_count: 0
- fixed_defects: DOCUMENT-IMPORT-S1-001, DOCUMENT-IMPORT-S1-002, DOCUMENT-IMPORT-S1-003
- remaining_defects: Module 4 fixed-sample matrix still to be audited after this verifier repair

## DOCUMENT-IMPORT-S1-002

- defect_id: DOCUMENT-IMPORT-S1-002
- severity: S1
- module: Document Library / Import Module
- page: Import / Document Library
- user_path: import UI008_TXT_A + UI008_DUPLICATE_A_COPY + UI008_TXT_B -> inspect source_manifest -> reload document library
- expected_behavior: same-content sources are identified by content_hash, ordinary source list contains only usable unique sources, duplicate sources are recorded with duplicate_of metadata, and restart recovery reads the same deduped truth
- actual_behavior: UI008_TXT_A and UI008_DUPLICATE_A_COPY were treated as two ordinary usable sources because source_manifest did not persist content_hash or duplicate metadata
- reproduce_steps: run `flutter test test/rc6_runtime_truth_blocker_repair_test.dart --plain-name "module4 UI008 duplicate content import records content hash and dedupes"` before the fix
- exact_error: expected `source_count = 2`, actual `source_count = 3`
- root_cause_category: state_not_persisted
- root_cause_evidence: `_writeSourceManifestFromInput` built source records from relative paths and file stats only; no content fingerprint was persisted, and duplicate input files stayed in `input/`
- minimal_fix_scope: compute a stable local content hash while writing source_manifest, keep the first source per hash, move repeated content to `duplicate_sources`, remove duplicate input files before downstream parsing, and add UI008 fixed-sample regression coverage
- allowed_files: `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`, `web/workbench/flutter_app/test/rc6_runtime_truth_blocker_repair_test.dart`, this registry
- forbidden_files: `capability_chain_status.json`, P0/P1/P2 gate reports, package/build artifacts
- white_box_result: pass
- black_box_result: pass
- regression_result: pass
- commit_id: this commit

Evidence:

```text
failing_test_before_fix = output/module_repair/module4_document_import/module4_ui008_duplicate_content_before_fix.log -> expected source_count 2, actual 3
targeted_after_fix = output/module_repair/module4_document_import/module4_ui008_duplicate_content_after_hash_fix.log -> All tests passed
working_tree_regression = output/module_repair/module4_document_import/module4_duplicate_import_regression_working_tree.log -> All tests passed
staged_snapshot_targeted_after_fix = output/module_repair/module4_document_import/module4_staged_snapshot_ui008_duplicate_after_fix.log -> All tests passed
staged_snapshot_regression = output/module_repair/module4_document_import/module4_staged_snapshot_duplicate_regression.log -> All tests passed
staged_snapshot_code_quality = output/module_repair/module4_document_import/module4_staged_snapshot_duplicate_flutter_analyze.log -> No issues found
capability_chain_status_json_unchanged = true
```

## DOCUMENT-IMPORT-S1-003

- defect_id: DOCUMENT-IMPORT-S1-003
- severity: S1
- module: Document Library / Import Module
- page: Document Library / Parse Documents
- user_path: import UI008_TXT_A + UI008_BAD_EMPTY -> organize documents -> inspect user-visible result and restart state
- expected_behavior: partial document parsing failures remain visible to the user, usable sources stay available, and parse_report is written when at least one source is usable
- actual_behavior: HEAD only used the core bridge pass/fail result, so a successful process with `failed_count > 0` was presented as a plain success message
- reproduce_steps: run `flutter test test/rc6_runtime_truth_blocker_repair_test.dart --plain-name "module4 UI008 parse partial failure reports failed sources"` before the fix
- exact_error: runtime did not surface `failed_count = 1` in `lastError` / user message
- root_cause_category: lifecycle_missing
- root_cause_evidence: `parseAndChunkSources` wrote the parse alias only when the bridge passed and never interpreted `document_understanding_manifest.json` counts for partial success
- minimal_fix_scope: read document understanding summary after parsing, write parse alias if any source is usable, and surface failed/skipped counts in user language
- allowed_files: `web/workbench/flutter_app/lib/rc6_runtime/rc6_runtime_controller_io.dart`, `web/workbench/flutter_app/test/rc6_runtime_truth_blocker_repair_test.dart`, this registry
- forbidden_files: `capability_chain_status.json`, P0/P1/P2 gate reports, package/build artifacts
- white_box_result: pass
- black_box_result: pass
- regression_result: pass
- commit_id: this commit

Evidence:

```text
working_tree_targeted = output/module_repair/module4_document_import/module4_parse_partial_failure_working_tree.log -> All tests passed
staged_snapshot_targeted_after_fix = output/module_repair/module4_document_import/module4_staged_snapshot_parse_partial_failure.log -> All tests passed
staged_snapshot_regression = output/module_repair/module4_document_import/module4_staged_snapshot_parse_regression.log -> All tests passed
staged_snapshot_code_quality = output/module_repair/module4_document_import/module4_staged_snapshot_parse_flutter_analyze.log -> No issues found
capability_chain_status_json_unchanged = true
```
